# TikTok God

Best free & open source tweak for TikTok app on iOS 10 - 13  

<img src="https://haoict.github.io/cydia/images/tiktokgodbanner.jpg" alt="TikTok God" width="414"/>

## Features
- Remove Ads
- Enable download for all videos
- More features comming soon... (download without watermark, change country)
- Support iOS 10 (not tested) - 11 (tested) - 12 (tested) - 13 (tested)
- Support latest TikTok version (If it doesn't work, you should update the app to latest version)

## Cydia Repo

[https://haoict.github.io/cydia](https://haoict.github.io/cydia)

## Screenshot

<img src="https://haoict.github.io/cydia/images/tiktokgodpref.png" alt="TikTok God Preferences" width="280"/>

## Building

[Theos](https://github.com/theos/theos) required.

```bash
make do
```

## Contributors

[haoict](https://github.com/haoict)

[ryannair05](https://github.com/ryannair05)

Contributions of any kind welcome!

## License

Licensed under the [GPLv3 License](./LICENSE), Copyright © 2020-present Hao Nguyen <hao.ict56@gmail.com>

## [Note] Advanced thingy for development
<details>
  <summary>Click to expand!</summary>
  
  Add your device IP in `~/.bash_profile` or in project's `Makefile` for faster deployment
  ```base
  THEOS_DEVICE_IP = 192.168.1.21
  ```

  Add SSH key for target deploy device so you don't have to enter ssh root password every time
  ```bash
  cat ~/.ssh/id_rsa.pub | ssh -p 22 root@192.168.1.21 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
  ```

  Build the final package
  ```bash
  FINALPACKAGE=1 make package
  ```

</details>