use std::env;
use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{Context, Result, bail};
use which::which;

use crate::logging::{info, success, warn};

pub fn run_shell_subcommand(
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

pub fn run_gc(aggressive: bool) -> Result<()> {
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

pub fn ensure_nix_installed() -> Result<()> {
    if which("nix").is_err() {
        bail!("Nix is not installed. Please install Nix first.");
    }
    success("Nix is installed.");
    Ok(())
}

pub fn ensure_experimental_features() -> Result<()> {
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

pub fn get_cli_path(cli: &str, fallback_nixpkg: Option<&str>) -> Result<PathBuf> {
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
