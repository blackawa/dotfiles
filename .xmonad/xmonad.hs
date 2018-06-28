import XMonad
import XMonad.Config.Desktop
import XMonad.Hooks.SetWMName
import XMonad.Layout.Spacing
import XMonad.Hooks.DynamicLog

main = xmonad =<< xmobar desktopConfig
        { terminal    = "urxvt"
        , borderWidth = 3
        , startupHook = myStartupHook
        , layoutHook = myLayoutHook
        }

myStartupHook = do
    spawn "sh ~/.fehbg"
    spawn "xcompmgr"
    setWMName "LG3D"
    spawn "fcitx-autostart"

myLayoutHook = spacing 8 $ Tall 1 (3/100) (1/2)
