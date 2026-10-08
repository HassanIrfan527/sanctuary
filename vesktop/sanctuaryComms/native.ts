/*
 * SanctuaryComms — the main-process half. Owns a unix socket that Quickshell
 * (quickshell/sanctuary/Comms.qml) connects to:
 *
 *   out  one JSON line per voice-state change (the newest is also sent to
 *        every client the moment it connects)
 *   in   one word per line: mute | deafen | leave — anything else is ignored
 *
 * The socket lives in $XDG_RUNTIME_DIR (mode 0700), so only this user can
 * reach it. Commands are handed to the renderer through next(): the renderer
 * keeps one call open and acts on what it returns — no code is ever injected.
 */

import { IpcMainInvokeEvent } from "electron";
import { unlinkSync } from "fs";
import { createServer, Server, Socket } from "net";

const PATH = (process.env.XDG_RUNTIME_DIR || "/tmp") + "/sanctuary-comms.sock";
const COMMANDS = new Set(["mute", "deafen", "leave"]);

let server: Server | null = null;
const clients = new Set<Socket>();
let last = JSON.stringify({ v: 1, inCall: false });

const queue: string[] = [];
let waiter: ((cmd: string | null) => void) | null = null;

function deliver(cmd: string) {
    if (waiter) {
        const w = waiter;
        waiter = null;
        w(cmd);
    } else {
        queue.push(cmd);
        if (queue.length > 8) queue.shift();
    }
}

function release() {
    if (waiter) {
        const w = waiter;
        waiter = null;
        w(null);
    }
}

function unlink() {
    try { unlinkSync(PATH); } catch { }
}

export function start(_: IpcMainInvokeEvent) {
    if (server) return;
    unlink();   // a socket left by a crashed Vesktop would block listen()

    server = createServer(sock => {
        clients.add(sock);
        sock.setEncoding("utf8");
        sock.write(last + "\n");

        let buf = "";
        sock.on("data", (d: string) => {
            buf += d;
            let i: number;
            while ((i = buf.indexOf("\n")) >= 0) {
                const line = buf.slice(0, i).trim();
                buf = buf.slice(i + 1);
                if (COMMANDS.has(line)) deliver(line);
            }
            if (buf.length > 256) buf = "";
        });
        const drop = () => clients.delete(sock);
        sock.on("close", drop);
        sock.on("error", drop);
    });
    server.on("error", () => { });
    server.listen(PATH);
}

export function stop(_: IpcMainInvokeEvent) {
    for (const c of clients) c.destroy();
    clients.clear();
    server?.close();
    server = null;
    unlink();
    queue.length = 0;
    release();
}

export function push(_: IpcMainInvokeEvent, json: string) {
    last = json;
    for (const c of clients) c.write(json + "\n");
}

// The renderer's long poll. Resolves with the next command, or null after 25s
// (or when a newer call replaces this one, e.g. after a renderer reload).
export function next(_: IpcMainInvokeEvent): Promise<string | null> {
    if (queue.length) return Promise.resolve(queue.shift()!);
    release();
    return new Promise(resolve => {
        waiter = resolve;
        setTimeout(() => {
            if (waiter === resolve) {
                waiter = null;
                resolve(null);
            }
        }, 25000);
    });
}
