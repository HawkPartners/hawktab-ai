# Resend Setup Checklist

## Account & Domain
- [ ] Create Resend account at resend.com
- [ ] Add and verify `crosstabai.com` domain (DNS records: SPF, DKIM, DMARC)
- [ ] Confirm domain shows "Verified" in Resend dashboard

## API Key
- [ ] Generate API key in Resend dashboard
- [ ] Add `RESEND_API_KEY=re_xxxxx` to `.env.local` (local dev)
- [ ] Add `RESEND_API_KEY` to Railway production environment variables

## Environment Variables (optional overrides)
- [ ] `RESEND_FROM_ADDRESS` — defaults to `Crosstab AI <notifications@crosstabai.com>`
- [ ] `NEXT_PUBLIC_APP_URL` — defaults to `https://app.crosstabai.com` (used for email links)

## Verification
- [ ] Send a test email from local dev (trigger a pipeline run)
- [ ] Verify email arrives, links work, formatting looks correct
- [ ] Toggle notification preference off in Settings, confirm no email on next run
- [ ] Remove `RESEND_API_KEY` from env, confirm pipeline still completes without errors
- [ ] Check Resend dashboard for delivery stats / bounces after first real sends
