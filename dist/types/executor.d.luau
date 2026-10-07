--!nonstrict
-- Optional executor-provided globals. Every one of these is probed at runtime
-- with `typeof(x) == "function"` before use, so declaring them here only exists
-- to keep strict analysis quiet -- absence is handled, not assumed.

declare function gethui(): Instance
declare function protect_gui(gui: Instance): ()
declare function syn_protect_gui(gui: Instance): ()
declare function getgenv(): { [string]: any }
declare function writefile(path: string, contents: string): ()
declare function readfile(path: string): string
declare function appendfile(path: string, contents: string): ()
declare function isfile(path: string): boolean
declare function isfolder(path: string): boolean
declare function makefolder(path: string): ()
declare function delfile(path: string): ()
declare function delfolder(path: string): ()
declare function listfiles(path: string): { string }
declare function setclipboard(text: string): ()
declare function queue_on_teleport(source: string): ()
declare function request(options: any): any
declare function identifyexecutor(): string
