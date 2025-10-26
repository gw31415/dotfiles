use std::env;
use std::path::PathBuf;

use anyhow::{Result, anyhow};

pub fn config_home() -> Result<PathBuf> {
    if let Some(path) = env::var_os("XDG_CONFIG_HOME") {
        return Ok(PathBuf::from(path));
    }
    let home = env::var_os("HOME").ok_or_else(|| anyhow!("HOME is not set."))?;
    Ok(PathBuf::from(home).join(".config"))
}
