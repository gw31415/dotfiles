use clap::{ArgAction, Parser, Subcommand};

#[derive(Debug, Parser, Clone)]
#[command(
    name = "dot",
    about = "Manage dotfiles via Nix",
    version,
    disable_help_flag = true
)]
pub struct Cli {
    #[arg(long = "help", action = ArgAction::Help, help = "Print help information and exit")]
    pub help: Option<bool>,
    #[arg(short, long)]
    pub all: bool,
    #[arg(short, long)]
    pub update: bool,
    #[arg(short = 'd', long)]
    pub darwin: bool,
    #[arg(short = 'h', long)]
    pub home: bool,
    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Debug, Clone, Subcommand)]
pub enum Commands {
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
