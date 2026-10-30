# SalesBot audio upload repair

User reports `upload_failed: Bucket not found` in the bot builder. Existing uploadSalesbotMedia and preview/runtime signers require the private salesbot-media bucket; production had no bucket or corresponding policies. Restore only that storage contract with the existing 20 MB limit, workspace operator insert and workspace member read. Preserve session security restrictions and all existing objects, bots and integrations. No application logic or dependencies change. Validate upload, signed download and workspace isolation; remove only the verification object.

## Production validation
Applied to exclusive Saúde Slim Supabase. Private bucket confirmed, 20 MB limit and two workspace policies. Real Storage API WAV upload and signed download returned identical bytes; unauthenticated public URL denied. Verification object removed. Stored policy expressions tested for owner upload/read, foreign workspace denial and malformed path denial. Existing session security policy retained. Security advisors fetched before and after; no new function, table or grant introduced. Exact bot-builder UI retry remains a user-session check.
