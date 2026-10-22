<img width="256" height="256" alt="SFRR" src="https://github.com/user-attachments/assets/33b93a20-6e5c-48f2-a78a-33b130cbf72d" />

An unofficial appimage for [Sonic Free Riders Recompiled](https://github.com/YuutaTsubasa/Free-Riders-Recompiled))
# How is the AppImage built
1. It runs an Github action that will run the build-appimage-ubuntu.sh script to build the AppImage.
3. Then after succesfully building it will create a Github release and uploads the output AppImage.

# What's the purpose of this repository?
1. The recomp currently doesn't have official AppImage yet.
2. To conveniently update it through [Gear Lever.](https://github.com/mijorus/gearlever)
3. To learn how AppImages are being built and distributed.

# Why reinvent the wheel?
While other platforms, already exist i made this repository purely as a learning experience and fun.

> Safety note
> This repository's Github Action workflow currently does not verify the integrity of the upstream binary. proceed with caution
> If the upstream binary or workflow ends up being compromised, the AppImage here could contain malicious code. use this at your own risk!
> The good thing is i can at least vet the binary before manually running the workflow, but security is still not guaranteed and AppImage may be out of date.
