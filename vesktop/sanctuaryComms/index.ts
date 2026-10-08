/*
 * SanctuaryComms — the renderer half. Reads Discord's own voice state and
 * hands it to native.ts, which serves it on a unix socket to Quickshell's
 * COMMS card (quickshell/sanctuary/Comms.qml, CommsCard.qml). Also runs the
 * three commands that card can send: mute, deafen, leave.
 *
 * Source of truth: ~/.dotfiles/vesktop/sanctuaryComms. It is COPIED into a
 * Vencord checkout and built by scripts/sanctuary/vencord.sh — edit it here.
 *
 * State line (JSON):
 *   { v, inCall, channel, guild, selfMute, selfDeaf,
 *     members: [{ id, name, me, mute, deaf, speaking }] }   you first, then A→Z
 */

import definePlugin, { PluginNative } from "@utils/types";
import { findByPropsLazy } from "@webpack";
import {
    ChannelStore, FluxDispatcher, GuildMemberStore, GuildStore, MediaEngineStore,
    SelectedChannelStore, UserStore, VoiceStateStore
} from "@webpack/common";

const Native = VencordNative.pluginHelpers.SanctuaryComms as PluginNative<typeof import("./native")>;

const ChannelActions = findByPropsLazy("selectVoiceChannel", "selectChannel");
const AudioActions = findByPropsLazy("toggleSelfMute", "toggleSelfDeaf");

const speaking = new Set<string>();
let running = false;
let timer: ReturnType<typeof setTimeout> | undefined;
let lastJson = "";

function snapshot() {
    const channelId = SelectedChannelStore.getVoiceChannelId();
    const channel = channelId ? ChannelStore.getChannel(channelId) : null;
    if (!channelId || !channel) return { v: 1, inCall: false };

    const meId = UserStore.getCurrentUser()?.id;
    const guildId = channel.guild_id;
    const states = VoiceStateStore.getVoiceStatesForChannel(channelId) ?? {};

    const members = Object.values(states).map((s: any) => {
        const user = UserStore.getUser(s.userId);
        const name = (guildId && GuildMemberStore.getNick(guildId, s.userId))
            || user?.globalName || user?.username || "?";
        return {
            id: s.userId,
            name,
            me: s.userId === meId,
            mute: !!(s.mute || s.selfMute),
            deaf: !!(s.deaf || s.selfDeaf),
            speaking: speaking.has(s.userId)
        };
    });
    members.sort((a, b) => a.me !== b.me ? (a.me ? -1 : 1) : a.name.localeCompare(b.name));

    return {
        v: 1,
        inCall: true,
        channel: channel.name || "call",
        guild: guildId ? GuildStore.getGuild(guildId)?.name ?? "" : "",
        selfMute: MediaEngineStore.isSelfMute(),
        selfDeaf: MediaEngineStore.isSelfDeaf(),
        members
    };
}

function push() {
    timer = undefined;
    const json = JSON.stringify(snapshot());
    if (json === lastJson) return;
    lastJson = json;
    Native.push(json).catch(() => { });
}

// Speaking events come in bursts; coalesce to one line per 60ms.
function schedule() {
    if (timer === undefined) timer = setTimeout(push, 60);
}

function run(cmd: string) {
    try {
        if (cmd === "mute") AudioActions.toggleSelfMute();
        else if (cmd === "deafen") AudioActions.toggleSelfDeaf();
        else if (cmd === "leave") ChannelActions.selectVoiceChannel(null);
    } catch {
        // Discord renamed the action module: fall back to the raw events it dispatches.
        if (cmd === "mute") FluxDispatcher.dispatch({ type: "AUDIO_TOGGLE_SELF_MUTE", context: "default", syncRemote: true });
        else if (cmd === "deafen") FluxDispatcher.dispatch({ type: "AUDIO_TOGGLE_SELF_DEAF", context: "default", syncRemote: true });
    }
    schedule();
}

async function loop() {
    while (running) {
        let cmd: string | null = null;
        try {
            cmd = await Native.next();
        } catch {
            await new Promise(r => setTimeout(r, 2000));
            continue;
        }
        if (running && cmd) run(cmd);
    }
}

export default definePlugin({
    name: "SanctuaryComms",
    description: "Serves voice state to the Sanctuary desktop (Quickshell COMMS card) and takes mute / deafen / leave from it.",
    authors: [{ name: "Harry", id: 0n }],

    flux: {
        VOICE_STATE_UPDATES: schedule,
        VOICE_CHANNEL_SELECT: schedule,
        RTC_CONNECTION_STATE: schedule,
        AUDIO_TOGGLE_SELF_MUTE: schedule,
        AUDIO_TOGGLE_SELF_DEAF: schedule,
        AUDIO_SET_SELF_MUTE: schedule,
        GUILD_MEMBER_UPDATE: schedule,
        SPEAKING({ userId, speakingFlags }: { userId: string; speakingFlags: number; }) {
            const was = speaking.has(userId);
            const now = speakingFlags !== 0;
            if (was === now) return;
            if (now) speaking.add(userId);
            else speaking.delete(userId);
            schedule();
        }
    },

    start() {
        running = true;
        lastJson = "";
        Native.start().then(() => { push(); loop(); }).catch(() => { });
    },

    stop() {
        running = false;
        speaking.clear();
        if (timer !== undefined) clearTimeout(timer);
        timer = undefined;
        Native.stop().catch(() => { });
    }
});
