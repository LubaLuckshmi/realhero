# RealHero visual assets

These are separate production image assets created with the built-in Image Generation tool from the approved five-screen reference. They contain no UI, navigation, card labels, or screenshot layers. Flutter renders all interface elements independently.

| File | Size | Use |
| --- | --- | --- |
| `assets/images/horizon.png` | 1024 × 1536, RGB | Today background and real-life journey thumbnails |
| `assets/images/workspace.png` | 1024 × 1536, RGB | Mission header and process background |
| `assets/images/avatar.png` | 1254 × 1254, RGB | Anonymous gender-neutral traveller avatar |
| `assets/images/leia-portrait.png` | 1254 × 1254, RGB | Separate AI guide portrait reconstructed from the approved reference |
| `assets/images/earth.png` | 1254 × 1254, RGBA | Orbital journey globe; actual transparent background |

Approved direction: deep navy / teal, warm realistic natural scene lighting, a hooded back-facing traveller with loose trousers, the real-world desk and cafe setting, and a luminous globe for the path screen. Names and portrait imagery in the reference were examples of personalization. The neutral avatar avoids assigning a gender to a new user.

## Final generation prompts

### Horizon
Photorealistic editorial portrait, 1024 × 1536. A small anonymous adult traveller in a black hooded jacket, backpack and loose straight athletic trousers stands back-facing on a rocky coast, looking toward ocean sunset. Mountains and rocky islands on the left; sun near the right horizon, golden reflection on dark teal water. Spacious deep navy sky in the upper third, shadowed rocks below, genuine natural textures, believable rim light. No text, UI, logos, watermark, face, fantasy portal, giant planet or glowing person.

### Workspace
Photorealistic editorial portrait, 1024 × 1536. A premium quiet cafe/work table beside a tall black-framed window at sunset, with soft urban buildings beyond, mature plant, black ceramic cup on the left, notebook and pen near the foreground, laptop partly visible on the right and thin closed notebooks farther back. Dark negative space upper left, navy/teal shadows, muted warm sunlight and natural dark wood. No person, readable text, logos, UI cards or watermark.

### Earth
A single realistically illuminated square Earth globe, showing Eurasia and Africa, occupying roughly 82% of the image width. Deep blue/teal oceans, natural continents, fine white clouds, warm restrained sunrise light at the upper right and deep navy shadow at the left; fine atmospheric rim. Transparent background requested and verified. No orbit rings, stars, icons, text, pedestal, frame, watermark or decoration. Orbit lines and progress states are rendered by Flutter code.

### Avatar
Image-edit reframe of `horizon.png`: square closer crop centered on the same hooded traveller's back, head and shoulders; preserve clothing, backpack, realistic coast, ocean sunset and warm rim light. Upper body occupies about 65% of image height. Face stays invisible, no gender cues, text, logos, UI, fantasy objects or frame. Opaque background preserved.

## Verification

All four outputs were visually inspected. PNG dimensions and modes were checked with Pillow. Earth alpha values span 0–255, so its outside background is genuinely transparent. No programmatic image editing or screen-image extraction was used.

## Leia portrait · 0.2.1

Created with the built-in Image Generation tool using `design/approved_reference.png` as the identity/style reference. This is a high-resolution reconstruction of the small fictional guide portrait, not an exact recovery of its original source image. The result was inspected and copied unchanged into `assets/images/leia-portrait.png`; the user profile avatar was not replaced. No OpenAI API key or paid server request was used for this asset.

Final prompt: Use case: identity-preserve. Asset type: standalone square avatar portrait for the AI guide Leia inside the existing RealHero Android app. The reference is the approved five-screen app design. Extract and faithfully reconstruct at useful image resolution the SAME fictional adult brunette guide whose small round portrait appears next to the label Лея in screens 02 and 03 and in the portrait example. Create ONE high-quality square photographic head-and-shoulders portrait only, no interface. Adult woman about 30–35, same oval face, dark medium-length wavy hair, warm natural skin, calm attentive expression, head slightly turned toward the viewer's right as in reference, natural warm sunset light on one cheek, deep dark navy teal unobtrusive backdrop. Center face with enough breathing room for a circular crop; face fills about 65% of square height. Preserve the reference's understated realistic photographic style and identity as closely as the small reference allows. No glamour retouching, no new fantasy aesthetic, no headset, no robot or sci-fi elements. No letters, labels, UI frames, circle outlines, watermark, or any other people. This is the assistant character portrait, not the user profile avatar. Return square image.
