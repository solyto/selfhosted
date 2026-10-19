# Report: default value of `EMAIL_CONFIRMATION`

date: 2026-10-14
read: true
job: show (`feature/show_email-confirmation-default-vlaue`)

## Question

`EMAIL_CONFIRMATION` currently defaults to `true`. Mailgun is the only mail
provider we support, so some self-hosters won't have working mail. Should the
default be `false`?

**Short answer:** Yes. Default to `false` and treat it as opt-in once mail is
configured. Before flipping it, the application maintainers should confirm the
open questions at the end of this report (especially Q1–Q3). Those answers could
change how urgent the change is, but they are unlikely to change which way we go.

## 1. Verified facts (from this repository)

| # | Fact | Source |
|---|------|--------|
| F1 | The shipped `.env` sets `EMAIL_CONFIRMATION=true` (Security block, next to `PASSWORD_MIN_LENGTH=12`, `PASSWORD_UNCOMPROMISED=true`). Added in `ba762d2` ("Added env variables to control security behavior", 2026-06-02). | `.env` (as committed, `git show HEAD:.env`) |
| F2 | The same `.env` leaves all mail settings empty: `MAILGUN_DOMAIN=`, `MAIL_FROM_ADDRESS=`, `MAIL_FROM_NAME=`. No `MAIL_MAILER` (or any other mailer selection) is set. | `.env` |
| F3 | The README documents `EMAIL_CONFIRMATION=true` under "7. Configure security (optional)" and does not say that it depends on working mail. | `README.md:191-199` |
| F4 | The README calls mail "optional" ("6. Configure mail (optional)") and documents only Mailgun values. The Mailgun secret is listed as needed only "if you need email functionality". | `README.md:149`, `README.md:181-189` |
| F5 | Mailgun is the only mail transport wired into the stack. `api` and `queue` receive only `MAILGUN_SECRET_FILE`; there are no SMTP/SES/Postmark variables or secrets. | `compose.yml:90`, `compose.yml:180`, `compose.yml:340-341` |
| F6 | `setup.sh` creates `secrets/mailgun_secret` **empty** and never asks about mail or `EMAIL_CONFIRMATION`. It only asks for domains and the ACME email. | `setup.sh:19-30`, `setup.sh:90` |
| F7 | The first user is created on the CLI (`docker exec -it solyto-api so users:create`). | `README.md:207-211` |
| F8 | `api` and `queue` are both on the `public` network, so they could reach Mailgun if it were configured. Outbound connectivity isn't the issue. | `compose.yml:149-152`, `compose.yml:201-204`, `compose.yml:305-314` |

**So by default:** someone who follows `setup.sh` and the README without doing
the optional step 6 ends up with email confirmation **on** and mail **not
configured**. Even someone who wants mail can only use Mailgun. A self-hoster
with their own SMTP server, or another provider, has no supported way to send
confirmation emails.

### Note on the local `.env` in the job worktree

The analyst saw `/workspace/.env` as empty (0 bytes) and `git status` reports it
as modified. I checked this. In the agent sandbox, `.env` is a character device
(`1,3`, which is `/dev/null`) mounted over the real file, probably to keep
secrets out of the session. It is not a real change to the file. Git can't diff
it ("unsupported file type"). The committed version (`git show HEAD:.env`) is
the upstream content described above, and that is what this report uses. I did
not touch the file.

## 2. What we cannot verify here (application behaviour)

What `EMAIL_CONFIRMATION` actually does is implemented in the `solyto/api-php`
and `solyto/app` images, not in this repository. The following are **assumptions
or unknowns, not facts**:

- Whether users can self-register, or whether accounts only come from
  `so users:create` (and maybe invites).
- Whether `users:create` marks the user as confirmed, or needs confirmation too.
- What an unconfirmed user experiences: a hard lockout (cannot log in / use the
  API) or only a banner or a few restricted features.
- What happens when a confirmation mail is sent with Mailgun unconfigured: the
  request fails (500), the queued job fails after 3 tries
  (`queue:work --tries=3`) and is dropped, or the mail is written to the log
  mailer.
- Whether there is an admin/CLI way to mark a user as confirmed or resend the
  mail.

The worst case is: self-registration exists, confirmation is a hard gate, and
the failed mail is silently dropped. In that case, every new user on a
mail-less instance is locked out and gets no explanation. The best case is: the
CLI-created admin is auto-confirmed and unconfirmed users only see a banner.
Then the impact is cosmetic, but it is still confusing.

## 3. Options

### A. Keep `true` (status quo)

- **Pro:** Secure by default. It blocks sign-ups with addresses the user
  doesn't own and helps against spam/bot accounts on publicly reachable
  instances. It also guarantees that password-reset and notification mails go
  to a real, owned address.
- **Con:** It conflicts with "mail is optional" (F4) and with the shipped empty
  mail config (F2, F6). Out of the box, the setting depends on something that
  isn't there. Operators who can't or won't use Mailgun (F5) can't satisfy it.
  Depending on Q1–Q3, users may be locked out with no visible cause, which
  becomes a support burden.

### B. Default to `false`

- **Pro:** Matches the actual default state (no mail) and the README's "mail
  is optional". A fresh install works without Mailgun. Turning it on stays
  available as a one-line opt-in for operators who have configured mail.
- **Con:** Unconfirmed addresses are accepted by default. On a publicly
  reachable instance with open self-registration, this makes it easier to
  create throwaway or bot accounts and to register with someone else's
  address. Password-reset mails could go to addresses the account owner
  doesn't control. (These mails can't be delivered without mail anyway.)
- **Mitigation:** Most self-hosted instances are personal or family-sized, and
  the first account is created on the CLI (F7). That limits the abuse surface,
  especially if registration is closed or invite-only (Q1).

### C. Keep `true`, document it better

Add a note in README sections 6 and 7 that `EMAIL_CONFIRMATION=true` requires
working Mailgun, plus a comment in `.env`.

- **Pro:** Small, keeps the secure default.
- **Con:** The default stays broken for anyone who skips the optional mail
  step, and docs are easy to miss. It doesn't help people who can't use
  Mailgun.

### D. Tie it to mail being configured

For example, confirmation is enforced only if `EMAIL_CONFIRMATION=true` **and**
a mailer is configured, or `setup.sh` asks "configure mail?" and sets both
together.

- **Pro:** Best behaviour on both kinds of install, with no silent lockout.
- **Con:** The runtime variant needs a change in the application image (out of
  scope for this repo). The `setup.sh` variant is doable here but only covers
  installs that go through `setup.sh`. Hidden "auto" behaviour can surprise
  people who explicitly set `true`.

## 4. Recommendation

1. **Change the default to `EMAIL_CONFIRMATION=false`** (Option B), in `.env`
   and `README.md:198`. The flag should match the install's actual default,
   which is no mail.
2. **Combine it with documentation from Option C.** In README section 7, state
   that `EMAIL_CONFIRMATION=true` requires working mail (section 6) and is
   recommended for instances with open registration. Add a matching comment in
   `.env`.
3. **Optionally, later:** Option D in `setup.sh` (ask whether to configure
   Mailgun, and if so set `EMAIL_CONFIRMATION=true`), and/or support for
   generic SMTP. SMTP support would fix the underlying "limited mail
   providers" problem, but needs changes in `compose.yml` and very likely in
   the application image.

Why: a secure default that doesn't work with the shipped configuration ends up
as a broken install rather than a secure one. The security benefit of `true`
only matters on instances that are public and allow open registration. Those
operators can turn it on with one line once mail works.

**Note for existing installs:** changing the shipped default doesn't affect
existing deployments, because their `.env` already contains
`EMAIL_CONFIRMATION=true`. Mention this in the release notes.

## 5. Open questions for the application maintainers

- **Q1:** Is there self-registration, and can it be disabled? If registration
  is CLI- or invite-only, the abuse argument for `true` gets much weaker.
- **Q2:** Is a user created via `so users:create` auto-confirmed?
- **Q3:** With `EMAIL_CONFIRMATION=true` and no working mailer, what does the
  user see (hard lockout vs. banner), and what happens to the mail (error,
  dropped after `--tries=3`, logged)?
- **Q4:** Which Laravel mailer is used when `MAIL_MAILER` is unset in the image?
  Would a `MAIL_MAILER=smtp` override plus `MAIL_HOST`/`MAIL_PORT`/... already
  work, or is Mailgun hard-coded?
- **Q5:** Is there an admin/CLI command to confirm a user manually or resend the
  confirmation mail? If yes, it belongs in the README as a recovery path.

## 6. Out of scope for this job

This job delivers only this report. No configuration or README changes were
made. Changing the default, the README/`.env` wording, `setup.sh` prompts and
SMTP support are follow-ups that need a human decision.
