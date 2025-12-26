// src/main.rs
use chrono::{NaiveDateTime, Local};
use std::collections::HashSet;
use std::env;
use std::fs::{File, OpenOptions};
use std::io::{self, BufRead, BufReader, Write};
use std::process;

#[derive(Debug, Clone)]
struct HistoryEntry {
    epoch: Option<i64>,
    cmd: String,
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().skip(1).collect();

    if args.get(0).map(|s| s == "--help").unwrap_or(false) {
        print_help();
        return Ok(());
    }

    let histfile = env::var("HISTFILE").unwrap_or_else(|_| {
        let home = env::var("HOME").unwrap_or_else(|_| ".".to_string());
        format!("{}/.bash_history", home)
    });

    // Load history into memory
    let mut history = load_history(&histfile)?;

    // Handle options
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "-c" => {
                history.clear();
            }
            "-d" => {
                i += 1;
                if i >= args.len() {
                    eprintln!("history -d requires an offset");
                    process::exit(1);
                }
                let offset = args[i].parse::<isize>().unwrap_or_else(|_| {
                    eprintln!("Invalid offset: {}", args[i]);
                    process::exit(1);
                });
                delete_entry(&mut history, offset);
            }
            "-s" => {
                i += 1;
                if i >= args.len() {
                    eprintln!("history -s requires a command argument");
                    process::exit(1);
                }
                append_entry(&mut history, &args[i]);
            }
            "-w" => {
                write_history(&history, &histfile)?;
            }
            "-a" => {
                let file = args.get(i + 1).map(|s| s.as_str()).unwrap_or(&histfile);
                append_history(&history, file)?;
            }
            "-r" => {
                let file = args.get(i + 1).map(|s| s.as_str()).unwrap_or(&histfile);
                let loaded = load_history(file)?;
                history.extend(loaded);
            }
            "-n" => {
                let file = args.get(i + 1).map(|s| s.as_str()).unwrap_or(&histfile);
                let new_entries = load_history(file)?;
                let mut seen: HashSet<(Option<i64>, String)> =
                    history.iter().map(|e| (e.epoch, e.cmd.clone())).collect();
                for e in new_entries {
                    if !seen.contains(&(e.epoch, e.cmd.clone())) {
                        history.push(e);
                    }
                }
            }
            other => {
                if let Ok(n) = other.parse::<usize>() {
                    display_history_n(&history, n);
                    return Ok(());
                } else {
                    eprintln!("Unsupported option: {}", other);
                    process::exit(1);
                }
            }
        }
        i += 1;
    }

    // Default: display all history
    display_history_n(&history, usize::MAX);

    Ok(())
}

fn print_help() {
    println!(
        "Usage: history [options] [N]\n\
         Options:\n\
         -c          Clear in-memory history\n\
         -d OFFSET   Delete history entry at OFFSET\n\
         -a [FILE]   Append new in-memory entries to file (default HISTFILE)\n\
         -n [FILE]   Read new entries from file and append (default HISTFILE)\n\
         -r [FILE]   Read file and append all entries (default HISTFILE)\n\
         -w [FILE]   Write in-memory history to file (overwrite, default HISTFILE)\n\
         -s ARG      Append ARG as single history entry\n\
         --help      Show this help message\n\
         N           Show last N entries\n\n\
         Environment Variables:\n\
         HISTFILE        Path to the history file (default ~/.bash_history)\n\
         HISTTIMEFORMAT  Format string for timestamps (used if set, otherwise default colored format is applied)\n\n\
         Notes:\n\
         - If HISTTIMEFORMAT is unset, colored timestamps [DD.MM.YY - HH:MM SS] are used.\n\
         - Colors: Gray[date], Cyan[day], Green[hour:minute], Orange[seconds]\n\n\
         Examples:\n\
         history                    # show all history with colored timestamps\n\
         history 20                 # show last 20 entries\n\
         HISTTIMEFORMAT='%d.%m.%y %H:%M:%S' history 10  # use custom timestamp format\n\
         history -s 'ls -la'        # append command to history"
    );
}

fn load_history<P: AsRef<std::path::Path>>(path: P) -> io::Result<Vec<HistoryEntry>> {
    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let mut entries = Vec::new();
    let mut epoch_opt: Option<i64> = None;

    for line in reader.lines() {
        let line = line?;
        if line.starts_with('#') {
            epoch_opt = line[1..].parse::<i64>().ok();
        } else {
            entries.push(HistoryEntry {
                epoch: epoch_opt,
                cmd: line.clone(),
            });
            epoch_opt = None;
        }
    }
    Ok(entries)
}

fn write_history(entries: &[HistoryEntry], file: &str) -> io::Result<()> {
    let mut f = File::create(file)?;
    for e in entries {
        if let Some(epoch) = e.epoch {
            writeln!(f, "#{}", epoch)?;
        }
        writeln!(f, "{}", e.cmd)?;
    }
    Ok(())
}

fn append_history(entries: &[HistoryEntry], file: &str) -> io::Result<()> {
    let mut f = OpenOptions::new().append(true).create(true).open(file)?;
    for e in entries {
        if let Some(epoch) = e.epoch {
            writeln!(f, "#{}", epoch)?;
        }
        writeln!(f, "{}", e.cmd)?;
    }
    Ok(())
}

fn delete_entry(history: &mut Vec<HistoryEntry>, offset: isize) {
    let idx = if offset >= 0 {
        offset as usize
    } else {
        let total = history.len();
        (total as isize + offset) as usize
    };
    if idx < history.len() {
        history.remove(idx);
    }
}

fn append_entry(history: &mut Vec<HistoryEntry>, cmd: &str) {
    history.push(HistoryEntry {
        epoch: Some(Local::now().timestamp()),
        cmd: cmd.to_string(),
    });
}

fn display_history_n(history: &[HistoryEntry], n: usize) {
    let histtimeformat = env::var("HISTTIMEFORMAT").ok();
    let start = if n >= history.len() { 0 } else { history.len() - n };

    for (i, entry) in history.iter().enumerate().skip(start) {
        let ts_str = if let Some(epoch) = entry.epoch {
            if let Some(fmt) = &histtimeformat {
                let dt = NaiveDateTime::from_timestamp_opt(epoch, 0)
                    .unwrap_or_else(|| Local::now().naive_local());
                dt.format(fmt).to_string()
            } else {
                let dt = NaiveDateTime::from_timestamp_opt(epoch, 0)
                    .unwrap_or_else(|| Local::now().naive_local());
                format!(
                    "\x1b[38;5;245m[\x1b[38;5;39m{}\x1b[38;5;245m - \x1b[38;5;42m{}\x1b[38;5;245m  \x1b[38;5;208m{}\x1b[38;5;245m]\x1b[0m",
                    dt.format("%d.%m.%y"),
                    dt.format("%H:%M"),
                    dt.format("%S")
                )
            }
        } else {
            "".to_string()
        };
        println!("{:>5} {}", i + 1, format!("{} {}", ts_str, entry.cmd));
    }
}

