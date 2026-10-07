# Omagent

A question box for [Omarchy](https://omarchy.org). Press `ALT + SPACE`, type a
question, and the answer appears in a card on screen.

**The pill answers in the UI itself.** It calls the Gemini API directly and
streams the reply into the card. It does not open a terminal and does not launch
`agy`, `opencode`, `claude`, `codex`, or any other agent CLI — a one-line
question should not cost you a window.

Local fork of `io.github.ellion369.omagent`, which did the opposite: it shelled
out to your default coding agent for everything.

## Setup

You need a Gemini API key from <https://aistudio.google.com/apikey>. Then either
export it in your shell profile:

```sh
export OMAGENT_GEMINI_KEY="your-key"
```

or write it to a config file, which is more reliable because the Omarchy shell
does not always inherit your login environment:

```sh
mkdir -p ~/.config/omagent
printf '{"geminiKey": "your-key"}\n' > ~/.config/omagent/config.json
chmod 600 ~/.config/omagent/config.json
```

`OMAGENT_GEMINI_KEY` wins over the config file. To use a different model, edit
the same file:

```json
{
  "geminiKey": "your-key",
  "modelLocal": "gemini-3.5-flash-lite",
  "modelWeb": "gemini-3.8-flash"
}
```

`modelLocal` and `modelWeb` are independent. A single `"model"` key overrides
both if you want one model everywhere.

Check it works without the UI:

```sh
~/.config/omarchy/plugins/soham.omagent/omagent-route --mode local -- "hello"
```

## Modes

The pill shows which mode is active. `Ctrl+T` switches them, or click the badge
in the pill or the button in the card footer.

| Mode | What it sends |
|---|---|
| `LOCAL` | The model plus a system instruction saying it has no internet. No tools are attached, so there is nothing to search with. |
| `WEB` | The same, plus `tools: [{"google_search": {}}]`, so the model can search live and the API returns the sources it used. |

`LOCAL` is a real capability limit rather than a request: the `google_search`
tool is simply not offered, so the model cannot reach the network even if it
wants to. The system instruction then tells it to admit when it cannot verify
something, so it does not guess silently.

The mode is remembered across restarts and applies to every request, so you can
flip it part-way through a conversation.

## Models

The two modes want different models, so each is configured separately.

| Mode | Default | Why |
|---|---|---|
| `LOCAL` | `gemini-3.5-flash-lite` | Answering from memory needs speed, not depth. |
| `WEB` | `gemini-3.8-flash` | Synthesising an answer from a few search snippets is easy, so this could just as well be the lite model. Set `modelWeb` to `gemini-3.5-flash-lite` for the same ~2s latency as `LOCAL`. |

Measured on a one-line question, median time to first token:

| Model | Time |
|---|---|
| `gemini-3.5-flash-lite` | 1.4s |
| `gemini-3.8-flash` | 3.1s |
| `gemini-3.5-flash` | 9.7s |
| `gemini-3.1-flash-lite` | 10.3s |

There is no `gemini-3.8-flash-lite`; only TTS variants. If you want to check
what your key can reach:

```sh
curl -s "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200" \
  -H "x-goog-api-key: $OMAGENT_GEMINI_KEY"
```

Note that the Flash Lite models reject `thinkingConfig` outright
("Request contains an invalid argument"), so thinking cannot be switched off on
them. They are simply fast on their own. The non-lite Flash models accept
`thinkingConfig`, which is worth setting if you want to trade latency for
quality on `WEB`.

Transient `429`/`500`/`502`/`503`/`504` responses are retried, silently, since the
retry happens before any text reaches the card. A failure after text has already
streamed is not retried, because that would duplicate the answer.

A **spent quota** is the exception: it is reported immediately rather than
retried, because waiting cannot refill a daily cap. The card shows one short line
instead of the API's multi-paragraph explanation.

### Stalls

About one request in four never receives response headers at all — the API
accepts the connection and then says nothing, indefinitely, not even after two
minutes. Timings from this machine:

| Phase | Time |
|---|---|
| TCP connect | 0.03s |
| TLS handshake | 0.04s |
| Response headers | 1.44s median, **or hangs forever** |
| First body byte | 0.00s |

So the transport is `http.client` rather than `urllib`, purely so the socket
deadline can cover the first response *line* and not just the headers. A single
long timeout turns every stall into minutes of a silent spinner.

- Header deadline: 6s for `LOCAL`, 25s for `WEB` (search grounding legitimately
  delays the response).
- Up to 5 attempts, since a healthy attempt only costs ~1.5s.
- A hard total budget of 20s for `LOCAL`, 90s for `WEB`, so a run of unlucky
  stalls cannot leave the pill spinning.

Measured after tuning, twelve consecutive `LOCAL` questions: median 2.1s, worst
case 11s, capped at 20s. Before, a stalled request could hang past 120s.

## Web search

`WEB` no longer uses Gemini's `google_search` grounding. That tool is metered
per query separately from ordinary prompts, so a free-tier key runs out quickly
and `WEB` died with `You exceeded your current quota` while `LOCAL` kept working.

Instead the router does the search itself and hands the results to the model as
context, so the model call is an ordinary unmetered prompt.

| Engine | Key | What it covers |
|---|---|---|
| Brave Search | `braveKey` | Real web search. Free tier 2000 queries/month. |
| DuckDuckGo Instant Answer | none | Encyclopedia entities and a few built-in calculators. |

Brave is used when `braveKey` is set. Otherwise DuckDuckGo's Instant Answer API
is used, which is free and does not bot-block — the same endpoint an earlier
version of this plugin used. Every other keyless backend was tested and refused
automated clients:

| Backend | Result |
|---|---|
| DuckDuckGo `html.duckduckgo.com` / `lite` | HTTP 202, CAPTCHA ("select all squares containing a duck") |
| Mojeek | JavaScript challenge page |
| searx.be, search.bus-hit.be, searxng.site, priv.au, search.inetol.net, opnxng.com | Connection refused |
| 4get.ca | HTTP 200, empty result set |
| Marginalia | Redirect, public API unreachable |
| Wikipedia API | Works, but encyclopedia only |

### What DuckDuckGo Instant Answer can and cannot do

It is an entity lookup, not a search engine, and it is worth being blunt about
what that means in practice:

| Query | Result |
|---|---|
| `roll a die` | ANSWER |
| `mount everest` | ABSTRACT (Wikipedia) |
| `elon musk` | RELATED |
| `capital of france` | empty |
| `100 usd to inr` | empty |
| `man city charged 114 counts` | empty |
| `what is the latest news today` | empty |

So it works for "who is X" and "tell me about X". It returns nothing for news,
current events, or most plain factual questions.

Because the API matches bare entities rather than sentences, the router strips
conversational scaffolding before searching: `tell me about mount everest` and
`explain python programming language` are reduced to `mount everest` and
`python programming language`, which is the difference between no results and a
full Wikipedia abstract.

When a lookup comes back empty the card shows `No web results` and the model is
told to answer from its own knowledge and say plainly that it could not check.
It is never given invented citations.

If you need real web search without paying Google, add a Brave key:

```json
{ "geminiKey": "your-key", "braveKey": "your-brave-key" }
```

Search failures degrade to "no results" rather than failing the answer.

## Keys

| Key | Function |
|---|---|
| `ALT + SPACE` | Open the pill |
| `Enter` | Send |
| `Ctrl+T` | Switch `LOCAL` / `WEB` |
| `Ctrl+C` | Stop the current answer |
| `Ctrl+N` | Clear the transcript |
| `Ctrl+Y` | Copy the last answer, or click any row |
| `Escape` | Hide the pill |
| `PageUp` / `PageDown` | Scroll the card |

The microphone button starts [Voxtype](https://github.com/basecamp/voxtype)
dictation if you have it installed.

## Conversation context

Gemini has no server-side session, so the pill resends the visible transcript on
every request. Only your questions and the model's answers are included — status
notes, source lines and errors are left out.

The router keeps the last 12 turns and trims from the front until the history
fits 24000 characters, so long conversations degrade gracefully instead of
failing. `Ctrl+N` clears it.

## Cost

Token counts per request are shown in the card header. Gemini 3 models bill each
search query separately in `WEB` mode, so `LOCAL` is the cheaper default for
anything the model already knows.

## Saved data

`~/.local/state/soham.omagent/last.json` holds the transcript, the selected mode,
token totals and the overlay position.

This is deliberately **not** `~/.local/state/omagent/`, which belongs to the
local agent harness and uses a different schema. The upstream plugin used that
path and the two files overwrote each other.

## Install

Already installed at `~/.config/omarchy/plugins/soham.omagent` and enabled in
`~/.config/omarchy/shell.json`. The Hyprland side lives in
`~/.config/hypr/bindings.lua`:

```lua
-- soham.omagent: begin
o.bind("ALT + SPACE", "Omagent", "omarchy-shell shell toggle soham.omagent")
hl.layer_rule({ match = { namespace = "omarchy-omagent" }, blur = true, ignore_alpha = 0.6 })
-- soham.omagent: end
```

`ALT+SPACE` was unassigned. On this machine Hyprland maps `SUPER` to modmask 64
and `ALT` to 8, so `SUPER+SPACE` was never an option; it is the Omarchy menu.

After any QML change:

```sh
omarchy restart shell
```

The overlay is `keepLoaded`, so a shell restart is what picks up new code.

## Development

```sh
# Print the exact request body instead of calling the API
OMAGENT_DRY_RUN=1 ~/.config/omarchy/plugins/soham.omagent/omagent-route \
  --mode web --history '[{"r":"user","t":"hi"}]' -- "and now?"

# Overlay errors
journalctl --user -f | grep -i omagent
```

`OMAGENT_CONFIG=/path/to/config.json` overrides the config file location.

## Remove

```sh
omarchy plugin remove soham.omagent
omarchy restart shell
```

Then delete the `soham.omagent` block from `~/.config/hypr/bindings.lua`, and
`~/.config/omagent/` if you no longer want the key on disk.

## License

MIT. See `LICENSE`.
