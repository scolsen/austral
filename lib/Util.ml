open Identifier
open Unix
open Error

let string_explode (s: string): char list =
  List.init (String.length s) (String.get s)

let string_implode (l: char list): string =
  String.init (List.length l) (List.nth l)

let read_stream_to_string stream: string =
  let rec read_stream stream =
    try
      let line = input_line stream in
      line :: (read_stream stream)
    with End_of_file ->
      []
  in
  String.trim (String.concat "\n" (read_stream stream))

let read_file_to_string (path: string): string =
  let stream = open_in path in
  let contents = read_stream_to_string stream in
  close_in stream;
  contents

let write_string_to_file (path: string) (contents: string): unit =
  let stream = open_out path in
  try
    Printf.fprintf stream "%s" contents;
    close_out stream;
    ()
  with _ ->
    close_out_noerr stream;
    err ("Failed to write to file: " ^ path)

let remove_char (s: string) (c: char)  =
  string_implode (List.filter (fun c' -> c <> c') (string_explode s))

let replace_char (s: string) (c: char) (r: string): string =
  let replace char =
    if char = c then
      string_explode r
    else
      [char]
  in
  string_implode (List.concat (List.map replace (string_explode s)))

let remove_leading (s: string) (n: int): string =
  String.sub s n ((String.length s) - n)

let parse_hex (s: string): int =
  int_of_string ("0x" ^ s)

let parse_bin (s: string): int =
  int_of_string ("0b" ^ s)

let parse_oct (s: string): int =
  int_of_string ("0o" ^ s)

let parse_ascii_char (s: string): int =
  match s with
  | "\\n" ->
     97
  | "\\r" ->
     13
  | "\\t" ->
     9
  | "\\\\" ->
     92
  | _ ->
     (match (string_explode s) with
      | [c] ->
         Char.code c
      | _ ->
         err "Character literal too long.")

let rec count_leading_whitespace (s: string): int =
  let chars = string_explode s in
  match chars with
  | ' '::rest ->
     1 + (count_leading_whitespace (string_implode rest))
  | _ ->
     0

let min_list (l: int list): int =
  match l with
  | first::rest ->
     List.fold_left min first rest
  | [] ->
     err "empty list passed to min_list"

let trim_common_whitespace (s: string): string =
  let lines = String.split_on_char '\n' s in
  let lines = List.map (fun s -> (count_leading_whitespace s, s)) lines in
  let min_whitespace: int = min_list (List.map (fun (w, _) -> w) lines) in
  let lines: string list = List.map (fun (_, s) -> remove_leading s min_whitespace) lines in
  String.concat "\n" lines

let process_triple_string (s: string): string =
  let lines = String.split_on_char '\n' s in
  match lines with
  | first::rest ->
     let first = if (String.equal (String.trim first) "") then
                   ""
                 else
                   first
     in
     (match (List.rev rest) with
      | last::body ->
         let last = if (String.equal (String.trim last) "") then
                      ""
                    else
                      last
         in
         let s = first ^ (String.concat "\n" (List.rev body)) ^ last in
         trim_common_whitespace s
      | [] ->
         first)
  | [] ->
     err "split_on_char returned empty"

let ident_set_eq a b =
  let sorter a b = compare (ident_string a) (ident_string b) in
  (List.sort sorter a) = (List.sort sorter b)

let get_exit_code = function
  | WEXITED i -> i
  | WSIGNALED i -> i
  | WSTOPPED i -> i

type command_output =
  CommandOutput of { command: string; code: int; stdout: string; stderr: string }

let run_command (command: string): command_output =
  let (stdout_chan, stdin_chan, stderr_chan) = open_process_full command [||] in
  let stdout = read_stream_to_string stdout_chan
  and stderr = read_stream_to_string stderr_chan in
  let proc_stat = close_process_full (stdout_chan, stdin_chan, stderr_chan) in
  CommandOutput {
      command = command;
      code = get_exit_code proc_stat;
      stdout = stdout;
      stderr = stderr
    }
