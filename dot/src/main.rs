mod app;
mod cli;
mod env;
mod logging;
mod nix;
mod utils;

use std::process::ExitCode;

use app::run;
use logging::error;

fn main() -> ExitCode {
    match run() {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            error(format!("{err:#}"));
            ExitCode::from(1)
        }
    }
}
