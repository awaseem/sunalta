# Clock studio lighting

`clock-app/Resources/ClockStudio.skybox/ClockStudio.exr` is Apple's unmodified
`studio_lighting_objectmode_v002.exr`, published for use in third-party renderers:

- [Apple's lighting environment documentation](https://developer.apple.com/documentation/arkit/specifying-a-lighting-environment-in-ar-quick-look)
- [Original EXR](https://developer.apple.com/sample-code/ar/studio_lighting_objectmode_v002.exr)

The on-demand RealityRenderer needs an explicit lighting environment. This provides
neutral studio fill and reflections alongside the clock's existing directional and
weekday lights. The environment is shared by the home clock and alarm preview; the
skybox texture is discarded after loading because the backdrop is a solid color.
