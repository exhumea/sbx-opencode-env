## Agentic setup with Docker sandboxes (humans-only)

> [!IMPORTANT]
> The agentic setup below is **humans only**: an agent must not run it, change it,
> or any config file or script involved in this setup.
> Only a human operator provisions sandboxes and authenticates accounts.

Before starting you need to `sudo apt install ssh-agent-filter` (or [download and compile from official repo](https://git.tiwe.de/ssh-agent-filter.git/about/))

1. [Install `sbx`](https://docs.docker.com/ai/sandboxes/install/) and run `sbx login`

2. Install some skills with [`npx skills`](https://www.skills.sh/) and import them with `sbx skills import`

3. Store your secrets (API keys for model providers) with
[`sbx secret import` and/or `sbx secret set[-custom]`](https://docs.docker.com/ai/sandboxes/configuration/credentials/).
Some nice token providers are:
   - <https://opencode.ai/console/> (nice free tier, per day)
   - <https://lbrouter.com/#ref=JT84ZMGV> (good free tier, per day)
   - <https://tokenharbor.ai/login?invite=TH-8H7X-QFPX> (good free tier, 7d rolling)
   - <https://developer.amd.com.cn/radeon/tokenfactory> (free tier ~ OK, complex signup)
   - <https://openrouter.ai/> (free tier ~ OK, some free [image-generation models](https://openrouter.ai/models?output_modalities=image&variant=free) and [decision models](https://openrouter.ai/models?output_modalities=decisions&variant=free))
   - <https://developers.cloudflare.com/workers-ai/> (free tier ~ OK, some free [decision models](https://developers.cloudflare.com/workers-ai/models/?search=decision))
   - <https://engy.ai/r/0235D4> (very low cost)
   - <https://agentrouter.org/register?aff=gDnH> (175$ signup bonus, GPT 6.1 Sol)
   - <https://freegg.app/sign-up?aff=8FY2> (100$ signup bonus, GPT 6.1 Sol)
   - <https://freepi.ai/?ref=m4setpu7> (free tier, complex setup, regular ads impression needed)

4. [Authenticate with `gh` CLI](https://docs.github.com/github-cli/github-cli/quickstart)
for your human and agentic accounts, and `export GH_AGENT=<agent-username>` in your `~/.bashrc`
(note: you MUST have an SSH key for both
[authentication](https://docs.github.com/authentication/connecting-to-github-with-ssh)
and [signing](https://docs.github.com/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key#telling-git-about-your-ssh-key), for both accounts)

5. `git submodule update --init`

6. Launch new OpenCode sandbox(es) with `./new_opencode_sandbox.sh`

7. Pair your sandbox with your OpenCode {[desktop](https://opencode.ai/desktop), [mobile](https://getopencode.app/), web} apps
**(beware pairing link is valid only once, run `./pair_opencode_sandbox.sh` to pair to another app)**

8. Start new _sessions_ in your OpenCode app **(beware to change the working directory before starting a _session_)**
