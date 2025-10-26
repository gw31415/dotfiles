use std::fs;
use std::path::Path;

pub fn read_file_bytes(path: &Path) -> Option<Vec<u8>> {
    fs::read(path).ok()
}
