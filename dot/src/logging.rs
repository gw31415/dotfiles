pub fn info(message: impl AsRef<str>) {
    println!("[INFO] {}", message.as_ref());
}

pub fn warn(message: impl AsRef<str>) {
    eprintln!("[WARN] {}", message.as_ref());
}

pub fn success(message: impl AsRef<str>) {
    println!("[SUCCESS] {}", message.as_ref());
}

pub fn error(message: impl AsRef<str>) {
    eprintln!("[ERROR] {}", message.as_ref());
}
