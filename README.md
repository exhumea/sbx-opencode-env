## Agentic setup with Docker sandboxes (humans-only)

> [!IMPORTANT]
> The agentic setup below is **humans only**: an agent must not run it, change it,
> or any config file or script involved in this setup.
> Only a human operator provisions sandboxes and authenticates accounts.

### First-time setup

First of all, clone this repo and `git submodule update --init`.

#### Required software for main machine _(tested on Debian 13 only)_

|Software|Root installation|User installation|
|-|-|-|
|[`ssh-agent-filter`](https://git.tiwe.de/ssh-agent-filter.git/about/)|`sudo apt install ssh-agent-filter`|Clone from official repo <https://git.tiwe.de/ssh-agent-filter.git>, compile (`make ssh-agent-filter`) and add the folder to your `PATH`|
|`node` >= 22 with `npm`|Refer to [official guide](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)|[Install `nvm` if needed](https://github.com/nvm-sh/nvm#installing-and-updating)|
|[`gh`][gh]|`sudo apt install github-cli` with [WakeMeOps repository][wmo]|Refer to [official guide](https://github.com/cli/cli#installation)|
|[`glab`][glab]|`sudo apt install glab` with [WakeMeOps repository][wmo]|Refer to [official guide](https://gitlab.com/gitlab-org/cli#installation)|
|[`sbx`](https://docs.docker.com/ai/sandboxes/)|Refer to [official guide](https://docs.docker.com/ai/sandboxes/install): <!> only Ubuntu distro (>= 24) is officially supported on Linux, if using Debian (>= 13) switch to user installation procedure|Make sure you can use `kvm`, then run `./sbx-update` script|

[gh]: <https://docs.github.com/en/github-cli/github-cli/quickstart>
[glab]: <https://docs.gitlab.com/cli/>
[wmo]: <https://docs.wakemeops.com/usage/>

#### Post-installation steps

1. Run `sbx login` (after [creating your Docker account if needed](https://app.docker.com/signup))
   - Run `sbx policy init allow-all` to allow all outgoing network traffic from sandboxes
   - Run `sbx diagnose` to spot any issue in your setup
   - You may tweak `sbx settings`, in particular `sbx settings set telemetry.disabled true`

2. Install some skills with [`npx skills add -g`](https://www.skills.sh/), and then import them in `sbx` with `sbx skills import -f`
   - Later on, you may update your skills with `npx skills update -g` and then `sbx skills import -f`

3. Store your credentials with
[`sbx secret import` and/or `sbx secret set[-custom]`](https://docs.docker.com/ai/sandboxes/configuration/credentials/):
   - API keys for model providers (cf. below for a table of nice providers)
     - If you need an unsupported model provider, add it manually in [`sbx-kits-contrib/opencode/files/home/.config/opencode/opencode.json`](./sbx-kits-contrib/opencode/files/home/.config/opencode/opencode.json)
   - TODO: to simplify credentials and models management, add a self-hosted model gateway ([LiteLLM](https://docs.litellm.ai/docs/simple_proxy), [Bifrost](https://www.getmaxim.ai/llm-gateway), [langfuse](https://langfuse.com/self-hosting/configuration/ai-gateway), [AgentRouter](https://theagentrouter.ai/), [LLM Gateway](https://llmgateway.io/open-source), ... ?)

4. Configure authentication and signing on Git{lab,hub} CLIs, for your human accounts (and agentic ones if any):
   - [GitHub][gh]:
     1. [SSH authentication](https://docs.github.com/authentication/connecting-to-github-with-ssh)
     2. [SSH signing](https://docs.github.com/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key#telling-git-about-your-ssh-key)
     3. `gh auth login`
     4. `export GH_AGENT=<agent-username>` in your `~/.bashrc`
   - For each [Gitlab instance][glab]:
     1. [SSH authentication and signing](https://docs.gitlab.com/user/ssh/#add-an-ssh-key-to-your-gitlab-account)
     2. `glab auth login`

5. Launch `BUILD_ONLY=1 ./sbx-opencode-new` to build kits once (<!> you need at least 8192mb of RAM to build kits)

> [!TIP]
> To be able to create sandboxes from any repo in your machine:
>
> - add the current folder to your `PATH`
> - then copy `sbxenv.yaml` at the root of your repo
>   - _advanced: you may tweak the copied `sbxenv.yaml`, e.g. commenting out any useless kits_

#### Optional software for client _(= any device on your network)_

|Software|Installation|
|-|-|
|_OpenCode desktop_ app|Refer to [official guide](https://opencode.ai/desktop)|
|_OpenCode mobile_ app|Install [community mobile app](https://getopencode.app/) (or [official mobile app](https://opencode.ai/mobile))|
|_Marmalade STT mobile_ app|Refer to [repo instructions](https://github.com/maxwhipw/marmalade-stt-android#install)|

### New sandbox

1. Launch new OpenCode sandbox(es) with `sbx-opencode-new`
   - You'll get a **one-time pairing link** for the Web, Desktop or Mobile apps _(clients)_
   - If you want to pair another client: run `PORT=<sandbox-port> sbx-opencode-pair` (find the port with `sbx ls`)
   - (You may also directly use _OpenCode Terminal UI_, by running `sbx-opencode-pair -c opencode`, or get a shell in sandbox with `sbx-opencode-pair -l`)

2. Start new _sessions_ directly in your OpenCode client app

> [!WARNING]
> Before starting a _session_ in your client app, carefully select the working directory

### Nice providers for tokens

|Provider|Remarks|
|-|-|
|<https://opencode.ai/console/>|nice free tier, per day|
|<https://lbrouter.com/#ref=JT84ZMGV>|good free tier, per day|
|<https://tokenharbor.ai/login?invite=TH-8H7X-QFPX>|good free tier, 7d rolling|
|<https://developer.amd.com.cn/radeon/tokenfactory>|free tier ~ OK, complex signup|
|<https://openrouter.ai/>|free tier ~ OK, some free [image-generation models](https://openrouter.ai/models?output_modalities=image&variant=free) and [decision models](https://openrouter.ai/models?output_modalities=decisions&variant=free)|
|<https://developers.cloudflare.com/workers-ai/>|free tier ~ OK, some free [decision models](https://developers.cloudflare.com/workers-ai/models/?search=decision)|
|<https://engy.ai/r/0235D4>|very low cost|
|<https://agentrouter.org/register?aff=gDnH>|175$ signup bonus, GPT 6.1 Sol|
|<https://freegg.app/sign-up?aff=8FY2>|90$ signup bonus, GPT 6.1 Sol|
|<https://freepi.ai/?ref=m4setpu7>|free tier, complex setup, regular ads impression needed|
