# Getting Brandhoop on Google Play, and keeping it updated

Everything here that a machine can do, launchkit has done or will do for you.
What follows needs your hands, and mostly your patience. Write down the date you
finish each step; the long ones run on a clock you cannot speed up.

## The timeline, honestly

Your developer account is, if you are an individual, a **personal** account, and
for personal accounts created after 13 November 2023 Google requires a closed
test with **at least 12 testers opted in continuously for 14 days** before you
may even apply for production. That is policy, not a queue you can jump, and an
organisation account is exempt from it. This is how the policy stood on
28 October 2026; the Play Console dashboard shows the numbers it wants today.

| Day | What happens |
|---|---|
| Today | Open the developer account. Identity verification can take days. |
| Day 1 to 7 | Meanwhile, finish everything in the repository: listing text, icon, privacy page, screenshots, signing key. |
| Day 0 of the test | Create the app, upload the first bundle by hand, start **internal testing**. It installs on real phones through a link straight away. |
| Same day | Fill the Console's forms, then start **closed testing** and get 12 or more testers opted in. The clock starts the day the twelfth is in, so do this first. |
| +14 days | Apply for production access. Google asks what the test taught you; answer properly. |
| +15 to +21 | Review. Reviews for a new account run long. |
| Then | Live on Play. |

Internal testing has no tester minimum and no waiting period, so people can use
the app long before there is a public listing.

## 1. Open a Google Play developer account today

Register at https://play.google.com/console as a personal account (25 USD,
once), start identity verification the same day, and give Play a public support
email address that is a personal one and never a company one.

Verification asks for a government ID and can take several days, which is why
this comes first even though nothing else depends on it yet. Play shows your
developer name and the support email on the listing; check what the Console says
will be public before you confirm. If your personal account was created before
13 November 2023 the testing requirement may not apply to you; the Console's
Dashboard says which requirements you are under.

## 2. Write the listing text and the release notes

Replace every LAUNCHKIT-UNEDITED line in `store/play/<locale>/` and
`store/whatsnew/` for en-IN, hi-IN with real text, then run
`python3 tools/store/check_store.py` to see what is left.

The limits are Play's own: 30 characters for the title, 80 for the short
description, 4,000 for the full one, 500 for release notes. The placeholder
files are longer than their limits on purpose, so `play.py` refuses a file you
forgot to edit, and `check_store.py` says which one. Have someone who reads each
language natively read that locale's text before it ships. The full description,
the privacy page and the Data safety form must all say the same thing about your
data.

## 3. Choose and draw the icon

Set `TAGLINE` in `tools/branding/make_icon.py`, run
`python3 tools/branding/make_icon.py --preview` to compare the marks, then
`python3 tools/branding/make_icon.py`, `flutter pub add --dev flutter_launcher_icons flutter_native_splash`,
`dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`,
and look at the result on a phone.

The script needs Pillow (`python3 -m pip install pillow`). It draws the store
icon, the Android adaptive pieces, the splash mark, the web icons, the social
card and the Play feature graphic. `flutter_launcher_icons` rewrites one iOS
build setting while it runs (`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
becomes `AppIcon`); put it back to `YES` before you commit. To draw your own mark
instead of a built-in one, write a `mark` function as described at the top of
`tools/branding/launchkit_draw.py` and pass its path with `--mark`.

## 4. Make the privacy policy and the terms true, and publish them

Open `site/privacy.html` and `site/terms.html`, make every yellow
LAUNCHKIT-MAKE-TRUE statement true for Brandhoop or rewrite it until it is,
delete the marks, publish `site/`, and open `https://pallavsharmaofficial.github.io/brandhoop/privacy.html` in a
browser to see it load with no sign-in.

Play checks the privacy URL, and it checks what the policy says against the
Data safety form and against the build, so a policy copied from another app is a
policy that is probably wrong. These pages are a starting point and not legal
advice. Do not delete a section because the claim in it is awkward; if the app
does something the policy does not mention, that is the thing to add. The
privacy URL must stay up for as long as the app is listed.

## 5. Take the phone screenshots

Put at least two and at most eight 24-bit PNG screenshots, no alpha channel and
1080 x 1920 by default, in `store/screenshots/`, named so they sort in the order
you want them shown.

The quickest honest way is a widget test that draws the real screens, as
`test/store_screenshots_test.dart` does once you have filled it in:
`flutter test --update-goldens test/store_screenshots_test.dart`. Otherwise take
them on a device and strip the alpha channel. Each side must be 320 to 3,840
pixels and the long side at most twice the short. Look at every one before you
upload it: a screenshot that shows something the listing does not mention, or the
other way round, is a policy problem. `check_store.py` checks the size and the
alpha channel.

## 6. Decide the Android permissions

Build a release APK, read the permissions that are really in it, and remove with
`tools:node="remove"` in `android/app/src/main/AndroidManifest.xml` every one the
app does not use:
`flutter build apk --release` and then
`"$(ls -d ${ANDROID_HOME:-$HOME/Library/Android/sdk}/build-tools/* | sort -V | tail -1)/aapt2" dump permissions build/app/outputs/flutter-apk/app-release.apk`.

Plugins add permissions you never wrote: an image picker can bring camera and
storage permissions, and Play answers storage and photo permissions with a
declaration form and sometimes a rejection. Removing one looks like this, and it
needs `xmlns:tools="http://schemas.android.com/tools"` on the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" tools:node="remove"/>
```

Every permission that stays must be explained on the privacy page and in the
Data safety answers, and must be something a person can use the app without. If
the app uses the network, the main manifest needs
`<uses-permission android:name="android.permission.INTERNET"/>`: Flutter adds it
to debug and profile builds only, so a release build without it has no network
and nothing says why. After this, update `store/README.md` and the privacy page's
permission list to match.

## 7. Make the upload key and give CI the secrets

Make the keystore once with
`mkdir -p ~/keystores && keytool -genkey -v -keystore ~/keystores/brandhoop-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`,
write `android/key.properties` (which git ignores), copy the keystore and its
password somewhere offline tonight, and set the three signing secrets on
GitHub.

`keytool` comes with the JDK. If your shell says it cannot find Java, use the
one Flutter uses: `flutter doctor -v` prints it as `Java binary at`, and
`keytool` is in the same folder. Losing the key means going through Play support
to reset it, which takes days; leaking it means someone else can sign updates to
your app. Keep it outside the repository. `android/key.properties`:

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/Users/you/keystores/brandhoop-upload.jks
```

`keyPassword` is the same as `storePassword` for the keystore format keytool
makes now. Use an absolute path for `storeFile`; Gradle does not expand `~`. Then
the secrets, each of which prompts for its value so none ends up in your shell
history:

```bash
base64 -i ~/keystores/brandhoop-upload.jks | gh secret set ANDROID_KEYSTORE_BASE64 --repo pallavsharmaofficial/brandhoop
gh secret set ANDROID_KEYSTORE_PASSWORD --repo pallavsharmaofficial/brandhoop
gh secret set ANDROID_KEY_ALIAS --repo pallavsharmaofficial/brandhoop --body upload
```

## 8. Build the signed bundle and run it on a real phone

Run `flutter analyze`, `flutter test`, `python3 tools/store/check_store.py` and
`flutter build appbundle --release`, confirm with
`keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep Owner`
that it is signed with your key and not `CN=Android Debug`, then install the
release build on a real Android phone and use every screen once.

A release build is minified, and minification breaks things debug builds never
show: a plugin that vanishes because nothing refers to it by name, a feature that
needs a permission you just removed. The bundle is at
`build/app/outputs/bundle/release/app-release.aab`. `check_store.py` must print
that it is clean before you go on; it will complain until the screenshots, the
icon and the site pages are real. Without `android/key.properties` the build
still succeeds, signed with the debug key, which Play will refuse; the `Owner`
line above is how you tell, so make sure the keystore step is done first.

## 9. Create the app in the Play Console

In the Console choose **Create app** with the name from
`store/play/en-IN/title.txt`, default language en-IN, type App, and
**Free**, and tick both declarations.

Free cannot be changed to paid later, and the package name, `in.pallavsharma.brandhoop`, is
fixed by the first bundle you upload and can never change after that. There is no
API for this step: Google gives a machine no way to create an app.

## 10. Upload the first bundle by hand and start internal testing

Go to Testing, Internal testing, **Create new release**, upload
`app-release.aab`, accept **Play App Signing** when it is offered, add your own
address as an internal tester, and install the app from the opt-in link on a
phone.

Google's API will not publish to an app that has never had a release, so this
one upload is made in the browser. After it, every update goes through CI or
`play.py`. Play App Signing means Google holds the key that signs what users
install and you hold only an upload key, which can be reset if you lose it.

## 11. Fill in the Console's forms from store/README.md

Complete the Dashboard's setup tasks: privacy policy URL `https://pallavsharmaofficial.github.io/brandhoop/privacy.html`,
Data safety, ads, content rating, target audience, app category (Shopping), the
other declarations it lists, contact details, and the store listing, graphics and
translations.

`store/README.md` holds the answers, which you wrote in step 2 to 6. None of these
forms has an API, so no tool can fill them: not `play.py`, not CI, not this
script. For the listing text and graphics you may either paste them or run
`"$LAUNCHKIT/play/play" --package in.pallavsharma.brandhoop listing` and then `graphics` from
the project folder; the API accepts both once the app exists. Answer the
questionnaires from what the app really does. Google compares them with the build
and with the privacy page, and a mismatch is the commonest reason for a
rejection. Choose a target audience that does not include children unless the
app has been built for the Families policy.

## 12. Start closed testing and recruit at least 12 testers

Create a closed testing track, put a Google Group of 15 or more testers on it,
release the internal build to it, and have every tester open the opt-in link,
install the app, and stay opted in for **14 days in a row**.

This is the 12-testers-for-14-days rule for personal developer accounts, and
the clock starts when the twelfth tester is in. Recruit 15 to 20, because if the
count falls below 12 you may have to start the 14 days again. The least painful way to
hold them is a Google Group: make one, add the addresses, and give the group's
address to Play as the tester list, so people joining or leaving never breaks
the opt-in. A tester who uninstalls costs nothing; one who leaves the track does.
Ask them for written feedback along the way. Google reads your answers about what
the test found, and a test that found nothing looks like a test that did not
happen. Write the date the twelfth tester opted in here: ______.

## 13. Switch on publishing from CI

Create the service account that lets a machine publish, with these four steps
and the longer account of them in launchkit's `play/README.md`: enable the
Google Play Android Developer API in a Google Cloud project, create a service
account and download its JSON key, invite the service account's email in the Play
Console with permission over this app only, and store the key with
`gh secret set PLAY_SERVICE_ACCOUNT_JSON --repo pallavsharmaofficial/brandhoop < ~/.config/play/service-account.json`.

If Google will not let you make a service account key because an organisation
policy blocks it, try a project under your own Google account with no
organisation above it; failing that, `play.py` can sign in as you through a
browser, for local commands only, as launchkit's `play/README.md` explains, and
CI publishing then waits until you have a key. Grant, for this app and not the
whole account, the permissions to release to testing tracks, to release to
production and to manage the store listing; the Console's names for them
change, so read their descriptions. New permissions can take hours to start
working, so a 403 straight afterwards usually just needs patience. Keep the key at `~/.config/play/service-account.json` with mode 600 so
`play.py` finds it, and never commit it. Check it with
`"$LAUNCHKIT/play/play" --package in.pallavsharma.brandhoop status`, which should list the
tracks rather than refuse.

## 14. Ship fixes through the pipeline while the 14 days run

Raise `version:` in `pubspec.yaml`, write what changed in
`store/whatsnew/whatsnew-<locale>` for each locale, and run **Release to Google
Play** from the Actions tab choosing the track your closed test uses, or push a
`v*` tag for an internal build.

Testers who see the app improve during the test are testers who stay. Play
rejects a build number it has seen before, so the number after the `+` in
`version:` must rise with every upload. The first closed track Play makes is
called `alpha`; if you named yours something else, the workflow's track list does
not include it, so use `"$LAUNCHKIT/play/play" --package in.pallavsharma.brandhoop promote --from internal --to <your track>`.

## 15. Apply for production access

When the test has run its 14 days with at least 12 testers opted in throughout,
open the Console's Dashboard, choose **Apply for production**, answer its
questions about the app, the test and your readiness, and wait for Google's
review.

Say what the testers actually found and what you changed because of it; vague
answers are refused. First reviews for a new account run long, so plan for a week
or more and do not schedule a launch around it.

## 16. Release to production in stages

Once production access is granted, put the tested build on production at 10
percent with
`"$LAUNCHKIT/play/play" --package in.pallavsharma.brandhoop promote --from alpha --to production --status inProgress --fraction 0.1`,
watch Android vitals for a few days, then widen it with
`"$LAUNCHKIT/play/play" --package in.pallavsharma.brandhoop rollout --track production --fraction 0.5`
and again with `--fraction 1.0`.

If something is wrong,
`"$LAUNCHKIT/play/play" --package in.pallavsharma.brandhoop halt --track production` stops the
rollout at once. A first production release is reviewed like any other change,
so it may sit in review before the percentage means anything. Decide what you
will watch before you start: crash rate, ANR rate, and anything the first
reviews say.

## 17. Keep it alive

After launch: keep the keystore offline and backed up, keep the privacy URL
working, raise the build number before every upload, and read the Play Console
inbox, because policy emails arrive there and carry deadlines.

Every release after the first is the same short loop: raise the version, write
the release notes, run **Release to Google Play**, check the internal build on a
phone, `promote` it, and widen the rollout. `docs/LAUNCH.md` has the checks to run
before each one. Apple's App Store is a separate path with its own account and
review, and nothing here covers it.
