# Play Console listing kit: Rhythm Workshop

Everything to paste into Play Console for the first release. Publisher: **HomiLabs Solutions** developer account.

## App details

| Field | Value |
| --- | --- |
| App name | Rhythm Workshop |
| Package | `com.homilabs.rhythmworkshop` (locked) |
| Default language | English (United States) |
| App or game | Game |
| Category | Educational (Game) |
| Free or paid | Free |
| Contains ads | No |
| In-app purchases | No |
| Email | info@homilabs.org |
| Privacy policy URL | https://awaizfatima08.github.io/rythm_workshop/privacy-policy.html |

## Store listing text

**Short description (80 max)**

> Sort toys to the beat! A calm music and sorting game for ages 3 to 6.

**Full description**

> Welcome to Rhythm Workshop, a warm wooden toy workshop where every toy you sort adds a note to a song.
>
> Toys ride along the conveyor belt. Drag each one into the right box: red toys in the red box, big ones here, small ones there. Every right answer rings a chime that lands on the beat, so your child builds a little melody as they play. At the end, Milo the monkey and Pip the penguin dance while "the song you made" plays back.
>
> Made for little hands and big feelings
> • No game over, no timers to beat and no failure sounds. A toy in the wrong box simply floats back to the belt.
> • Children can never be "off the beat": a right answer always counts, and the music waits for them.
> • Big touch targets, one-finger dragging, no reading needed.
> • Every colour also has a shape (red ●, blue ■, yellow ★), so colour-blind children can play too.
>
> What children practise
> • Sorting by colour, size, shape and meaning (fruit or vegetable)
> • Spotting and continuing a simple pattern
> • Feeling a steady beat
> • Careful finger control
>
> 12 levels in 4 worlds, all open from the start. English and Urdu voice.
>
> For parents
> • Works fully offline, with no internet permission at all.
> • No ads, no purchases, no accounts, no tracking. Nothing leaves the device.
> • Parent settings sit behind a grown-up check: session length with a gentle "goodnight" ending, calm mode (softer colours, slower belt), volume, vibration and voice language.
>
> Rhythm Workshop is free, from HomiLabs Solutions.

## Graphics (in `store-assets/`)

| Asset | File |
| --- | --- |
| App icon 512×512 | `store-assets/icon-512.png` |
| Feature graphic 1024×500 | `store-assets/feature-graphic-1024x500.png` |
| Phone screenshots (landscape) | `store-assets/screenshots/` |

## App content forms

**Target audience and content**: ages **5 and under** and **6–8**. Appeal to children: yes. This enrolls the app in the Families program; the app already meets its rules (no ads, no data collection, parental gate on settings).

**Data safety**
- Does your app collect or share any of the required user data types? **No.**
- Is all user data encrypted in transit? Not applicable (no data leaves the device).
- Do you provide a way for users to request that their data is deleted? Not applicable. Stars and settings stay on the device; "Reset progress" or uninstalling removes them.
- Result shown on Play: **No data collected · No data shared**.

**Content rating (IARC questionnaire)**: category *Game*. Answer **No** to violence, fear, sexuality, language, controlled substances, gambling, user interaction, sharing location, digital purchases and unrestricted internet. Expected rating: **Everyone / PEGI 3**.

**Ads**: No. **App access**: all functionality is available without special access. The parent settings answer is "grown-up check: solve a multiplication problem shown on screen".

**Government apps / financial features / health**: No.

**News app**: No.

## Release steps (owner)

1. Play Console → Create app (values above).
2. Upload `releases/v1.0.0-1/rhythm-workshop-1.0.0-1.aab` to **Internal testing**; accept Play App Signing.
3. Complete Store listing, App content and Data safety from this file.
4. Enable GitHub Pages for the privacy policy (see below) and check the URL opens.
5. New personal developer accounts need a **closed test with 12+ testers for 14 days** before production.

**GitHub Pages**: repo → Settings → Pages → *Deploy from a branch* → `main`, folder `/docs`. The policy is then at the URL above.

## Notes from testing

- Target SDK 36, min SDK 24. Release APK/AAB has **no INTERNET permission** (checked with `aapt2 dump permissions`).
- Upload key: `.secrets/rhythm-workshop-upload.keystore` (alias `upload`); passwords in `.secrets/rhythm-workshop-upload-keystore-credentials.txt`. Both are in the local and Drive backups, never in GitHub. Upload certificate SHA-1 `1F:3D:8C:93:FD:6C:50:B6:B8:F2:40:EB:CF:68:77:EF:2B:D4:39:1C`.
