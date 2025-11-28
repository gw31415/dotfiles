use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;

use anyhow::{Context, Result, bail};
use clap::Parser;
use dialoguer::{Confirm, Select};

use crate::cli::{Cli, Commands};
use crate::env::config_home;
use crate::logging::{info, success, warn};
use crate::nix::{
    ensure_experimental_features, ensure_nix_installed, get_cli_path, run_gc, run_shell_subcommand,
};
use crate::utils::read_file_bytes;

pub fn run() -> Result<()> {
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
            bail!(format!("Failed to {action} home-manager."));
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

fn intro_messages(home_manager_path: &Path) {
    println!("dot by @gw31415");
    println!("GitHub: https://github.com/gw31415/dotfiles");
    println!();
    info("Starting the setup process...");
    info("Checking the environment...");
    info(format!("Target path: {}", home_manager_path.display()));
}
