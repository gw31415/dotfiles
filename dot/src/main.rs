use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode};

use anyhow::{Context, Result, anyhow, bail};
use clap::{ArgAction, Parser, Subcommand};
use dialoguer::{Confirm, Select};
use which::which;

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            error(format!("{err:#}"));
            ExitCode::from(1)
        }
    }
}

#[derive(Debug, Parser, Clone)]
#[command(
    name = "dot",
    about = "Manage dotfiles via Nix",
    version,
    disable_help_flag = true
)]
struct Cli {
    #[arg(long = "help", action = ArgAction::Help, help = "Print help information and exit")]
    help: Option<bool>,
    #[arg(short, long)]
    all: bool,
    #[arg(short, long)]
    update: bool,
    #[arg(short = 'd', long)]
    darwin: bool,
    #[arg(short = 'h', long)]
    home: bool,
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Debug, Clone, Subcommand)]
enum Commands {
    /// Open the development shell (nix develop)
    Sh {
        #[arg(trailing_var_arg = true)]
        command: Vec<String>,
    },
    /// Garbage collect nix store paths
    Gc {
        #[arg(long)]
        aggressive: bool,
    },
}

fn run() -> Result<()> {
    let all_args: Vec<String> = env::args().collect();
    let args_len = all_args.len().saturating_sub(1);
    let cli = Cli::parse_from(all_args.clone());

    let config_home = config_home()?;
    let home_manager_path = config_home.join("home-manager");
    let env_nix = home_manager_path.join("env.nix");
    let flake_nix = home_manager_path.join("flake.nix");
    let installed = flake_nix.exists();
    let was_installed = installed;
    let is_darwin = cfg!(target_os = "macos");

    if !is_darwin && cli.darwin {
        warn("nix-darwin is not supported on this system. Ignoring the flag.");
    }

    match cli.command.clone() {
        Some(Commands::Sh { command }) => {
            run_shell_subcommand(command, &home_manager_path, installed)?;
            return Ok(());
        }
        Some(Commands::Gc { aggressive }) => {
            if !installed {
                bail!("Not installed. To install, run without the subcommand first.");
            }
            run_gc(aggressive)?;
            return Ok(());
        }
        None => {}
    }

    if !installed {
        intro_messages(&home_manager_path);
        ensure_nix_installed()?;
        ensure_experimental_features()?;
        info(format!("Installing path: {}", home_manager_path.display()));

        if home_manager_path.exists() {
            bail!(format!(
                "The target path {} already exists. Please remove it first.",
                home_manager_path.display()
            ));
        }

        fs::create_dir_all(&config_home)
            .with_context(|| format!("Failed to create {}", config_home.display()))?;

        info("Cloning the dotfiles...");
        let git = get_cli_path("git", None)?;
        let status = Command::new(git)
            .arg("clone")
            .arg("https://github.com/gw31415/dotfiles")
            .arg(&home_manager_path)
            .status()
            .context("Failed to execute git clone")?;
        if !status.success() {
            bail!("Failed to clone the dotfiles repository.");
        }
        success(format!(
            "Downloaded dotfiles to {}.",
            home_manager_path.display()
        ));

        if env_nix.exists() {
            println!();
            println!("> {}", env_nix.display());
            let env_contents = fs::read_to_string(&env_nix)
                .with_context(|| format!("Failed to read {}", env_nix.display()))?;
            println!("{env_contents}");
            println!();
            info(format!(
                "If the information in {} does not match, the build will fail.",
                env_nix.display()
            ));
            info(format!(
                "You can edit {} before running the next command.",
                env_nix.display()
            ));
            let continue_install = Confirm::new()
                .with_prompt("Continue installation?")
                .default(true)
                .interact()?;
            if !continue_install {
                let options = [
                    format!(
                        "Leave {} (edit env.nix and run the command again)",
                        env_nix.display()
                    ),
                    format!(
                        "Remove {} (re-run the script to download again)",
                        env_nix.display()
                    ),
                ];
                let selection = Select::new()
                    .with_prompt(format!(
                        "Do you want to clean {}?",
                        home_manager_path.display()
                    ))
                    .items(&options)
                    .default(0)
                    .interact()?;
                if selection == 1 {
                    fs::remove_dir_all(&home_manager_path).with_context(|| {
                        format!("Failed to remove {}", home_manager_path.display())
                    })?;
                    info("Removed the downloaded dotfiles.");
                } else {
                    info(format!(
                        "Please edit {} and re-run the script to continue the installation.",
                        env_nix.display()
                    ));
                }
                return Ok(());
            }
        }
    }

    if cli.update {
        info("Updating flake.lock...");
        let flake_lock = home_manager_path.join("flake.lock");
        let hash_before = read_file_bytes(&flake_lock);
        let status = Command::new("nix")
            .args(["flake", "update", "--flake"])
            .arg(&home_manager_path)
            .arg("--commit-lock-file")
            .status()
            .context("Failed to execute nix flake update")?;
        if !status.success() {
            bail!("Failed to update flake.lock.");
        }
        let hash_after = read_file_bytes(&flake_lock);
        if hash_before
            .as_ref()
            .map(|before| {
                hash_after
                    .as_ref()
                    .map(|after| before == after)
                    .unwrap_or(false)
            })
            .unwrap_or(false)
        {
            info("No changes. Update skipped.");
        } else {
            success(format!(
                "Updated {}.",
                home_manager_path.join("flake.lock").display()
            ));
        }
    }

    if args_len == 0 || cli.home || cli.all {
        info("Switching home-manager...");
        let home_manager = get_cli_path("home-manager", Some("home-manager"))?;
        let status = Command::new(home_manager)
            .arg("switch")
            .current_dir(&home_manager_path)
            .status()
            .context("Failed to execute home-manager switch")?;
        if !status.success() {
            let action = if was_installed { "update" } else { "install" };
            bail!(format!("Failed to {} home-manager.", action));
        }
    }

    if is_darwin && (cli.darwin || cli.all) {
        info("Switching darwin-rebuild...");
        let status = Command::new("sudo")
            .args(["nix", "run", ".#nix-darwin", "--", "switch", "--flake", "."])
            .current_dir(&home_manager_path)
            .status()
            .context("Failed to execute nix-darwin switch")?;
        if !status.success() {
            bail!("Failed to switch darwin-rebuild.");
        }
    }

    success("Success.");
    Ok(())
}

fn run_shell_subcommand(
    command: Vec<String>,
    home_manager_path: &Path,
    installed: bool,
) -> Result<()> {
    if !installed {
        bail!("Not installed. To install, run without the subcommand first.");
    }
    if env::var("DOT_DEVSHELL")
        .map(|value| !value.is_empty())
        .unwrap_or(false)
    {
        warn("You are already in the devShell. Cancelled.");
        std::process::exit(1);
    }
    info("Entering the devShell...");
    let mut develop = Command::new("nix");
    develop.arg("develop").arg("--impure").arg("-c");
    if command.is_empty() {
        let shell = env::var("SHELL").unwrap_or_else(|_| "/bin/bash".to_string());
        develop.arg(shell);
    } else {
        develop.args(&command);
    }
    let status = develop
        .current_dir(home_manager_path)
        .env("DOT_DEVSHELL", "1")
        .status()
        .context("Failed to execute nix develop")?;
    info("Exiting the devShell...");
    let code = status.code().unwrap_or(1);
    std::process::exit(code);
}

fn run_gc(aggressive: bool) -> Result<()> {
    info("Cleaning up...");
    let status = if aggressive {
        Command::new("nix-collect-garbage")
            .arg("-d")
            .status()
            .context("Failed to execute nix-collect-garbage")?
    } else {
        Command::new("nix")
            .args(["store", "gc", "-v"])
            .status()
            .context("Failed to execute nix store gc")?
    };
    if !status.success() {
        bail!("Failed to clean up.");
    }
    if aggressive {
        success("Cleaned up aggressively.");
    } else {
        success("Cleaned up.");
    }
    Ok(())
}

fn intro_messages(home_manager_path: &Path) {
    println!("dot by @gw31415");
    println!("GitHub: https://github.com/gw31415/dotfiles");
    println!();
    info("Starting the setup process...");
    info("Checking the environment...");
    info(format!("Target path: {}", home_manager_path.display()));
}

fn ensure_nix_installed() -> Result<()> {
    if which("nix").is_err() {
        bail!("Nix is not installed. Please install Nix first.");
    }
    success("Nix is installed.");
    Ok(())
}

fn ensure_experimental_features() -> Result<()> {
    let output = Command::new("nix")
        .arg("show-config")
        .output()
        .context("Failed to execute `nix show-config`")?;
    if !output.status.success() {
        bail!("`nix show-config` command failed.");
    }
    let stdout =
        String::from_utf8(output.stdout).context("`nix show-config` output is not valid UTF-8.")?;
    let Some(line) = stdout
        .lines()
        .find(|line| line.trim_start().starts_with("experimental-features"))
    else {
        bail!("experimental-features is not set.");
    };
    let features_part = line.split_once('=').map(|(_, value)| value.trim());
    let features: Vec<&str> = features_part
        .unwrap_or("")
        .split_whitespace()
        .filter(|entry| !entry.is_empty())
        .collect();
    if !(features.contains(&"nix-command") && features.contains(&"flakes")) {
        bail!("nix-command and/or flakes are not set.");
    }
    success("nix-command and flakes are set.");
    Ok(())
}

fn get_cli_path(cli: &str, fallback_nixpkg: Option<&str>) -> Result<PathBuf> {
    if let Ok(path) = which(cli) {
        return Ok(path);
    }
    let fallback = fallback_nixpkg.unwrap_or(cli);
    let output = Command::new("nix")
        .args(["path-info", &format!("nixpkgs#{fallback}")])
        .output()
        .context("Failed to execute `nix path-info`")?;
    if !output.status.success() {
        return Ok(PathBuf::from(cli));
    }
    let nix_store_path = String::from_utf8(output.stdout)
        .context("`nix path-info` output is not valid UTF-8.")?
        .trim()
        .to_string();
    if nix_store_path.is_empty() {
        return Ok(PathBuf::from(cli));
    }
    Ok(Path::new(&nix_store_path).join("bin").join(cli))
}

fn config_home() -> Result<PathBuf> {
    if let Some(path) = env::var_os("XDG_CONFIG_HOME") {
        return Ok(PathBuf::from(path));
    }
    let home = env::var_os("HOME").ok_or_else(|| anyhow!("HOME is not set."))?;
    Ok(PathBuf::from(home).join(".config"))
}

fn read_file_bytes(path: &Path) -> Option<Vec<u8>> {
    fs::read(path).ok()
}

fn info(message: impl AsRef<str>) {
    println!("[INFO] {}", message.as_ref());
}

fn warn(message: impl AsRef<str>) {
    eprintln!("[WARN] {}", message.as_ref());
}

fn success(message: impl AsRef<str>) {
    println!("[SUCCESS] {}", message.as_ref());
}

fn error(message: impl AsRef<str>) {
    eprintln!("[ERROR] {}", message.as_ref());
}
