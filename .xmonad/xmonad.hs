import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
import XMonad.Layout
import XMonad.Layout.Grid
import XMonad.Layout.ShowWName
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeysP)
import System.Environment(getEnv)
import System.IO

myBorderWidth = 2
myTerminal = "xterm"
myWorkspaces = ["Browser"] ++ map show [2..6]

myManageHook = manageDocks <+> manageHook defaultConfig

myLayoutHook = showWName $ avoidStruts (Grid ||| Full ||| tiled)
    where
        tiled = Tall nmaster delta ratio
        nmaster = 1
        ratio = 1/2
        delta = 3/100

myLogHook p = dynamicLogWithPP $ xmobarPP
    { ppOutput = hPutStrLn p
    , ppTitle = xmobarColor "green" "" . shorten 50
    }

myStartupHook = setWMName "LG3D"

myHandleEventHook = handleEventHook defaultConfig <+> fullscreenEventHook

runXmobar home = "xmobar " ++ home ++ "/.xmobarrc"

myConf p = ewmh defaultConfig
    { handleEventHook = myHandleEventHook
    , manageHook = myManageHook
    , borderWidth = myBorderWidth
    , terminal = myTerminal
    , workspaces = myWorkspaces
    , layoutHook = myLayoutHook
    , logHook = myLogHook p
    }
main = do
    myHome <- getEnv "HOME"
    xmproc <- spawnPipe $ runXmobar myHome
    xmonad $ (myConf xmproc) {
        startupHook = startupHook (myConf xmproc) >> myStartupHook
    }`additionalKeysP`
        [ ("M4-<Esc>", spawn "gnome-screensaver-command -l")
        , ("<XF86Sleep>", spawn "gnome-screensaver-command -l")
        ]

