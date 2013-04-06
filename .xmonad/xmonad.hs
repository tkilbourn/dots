import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Layout
import XMonad.Layout.Grid
import XMonad.Layout.ShowWName
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO

myBorderWidth = 2
myTerminal = "xterm"
myWorkspaces = ["Browser"] ++ map show [2..6]

myManageHook = manageDocks <+> manageHook defaultConfig

myLayoutHook = showWName $ avoidStruts (tiled ||| Full ||| Grid)
    where
        tiled = Tall nmaster delta ratio
        nmaster = 1
        ratio = 1/2
        delta = 3/100

myLogHook p = dynamicLogWithPP $ xmobarPP
    { ppOutput = hPutStrLn p
    , ppTitle = xmobarColor "green" "" . shorten 50
    }

runXmobar = "xmobar /home/tkilbourn/.xmobarrc"

main = do
    xmproc <- spawnPipe runXmobar
    xmonad $ defaultConfig
        { manageHook = myManageHook
        , borderWidth = myBorderWidth
        , terminal = myTerminal
        , workspaces = myWorkspaces
        , layoutHook = myLayoutHook
        , logHook = myLogHook xmproc
        } `additionalKeys`
        [ ((mod4Mask, xK_Escape), spawn "gnome-screensaver-command -l")
        ]

