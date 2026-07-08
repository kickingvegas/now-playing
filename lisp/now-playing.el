;;; now-playing.el --- macOS Music Player Interface  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Charles Choi

;; Author: Charles Choi <kickingvegas@gmail.com>
;; Keywords: tools
;; Version: 0.9.1-rc.1
;; Package-Requires: ((emacs "30.1") (transient "0.9.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Now Playing is an Emacs “now playing” interface to the macOS Music app.

;; Now Playing provides a Transient menu interface to control Music app with the
;; following commands:

;; - Pause/Play (SPC)
;; - Previous (p) and Next (n) Track
;; - Open (launch) Music app (o)
;; - Increase (<up>) and Decrease (<down>) volume
;; - Refresh current track (r)

;; Run the command M-x now-playing-tmenu to launch the Now Playing interface.

;; Now Playing is intended to be an ancillary interface to the Music app,
;; providing only a subset of controls to it. It has no long-term agenda to be a
;; full-featured client of Music app.

;; INSTALL

;; The Transient interface and commands for polling are auto-loaded so no
;; configuration is necessary. That said, users might find it convenient to make
;; a keybinding to the Transient menu `now-playing-tmenu' as follows:

;; (keymap-global-set "<f14>" #'now-playing-tmenu)

;;; Code:
(require 'transient)



;;; Variables and Constants

(defgroup now-playing nil
  "Group settings for Now Playing.

Now Playing is an Emacs “now playing” interface to the macOS Music app."
  :group 'convenience)

(defvar now-playing--poll-timer nil
  "Timer for polling current track.")

(defvar now-playing--volume nil
  "Music app volume.")

(defvar now-playing--current-track-cache nil
  "Cache value of Music app current track.")

(defvar now-playing--current-track-log ""
  "Music app log current track.")

(defcustom now-playing-volume-delta
  5
  "Change increment for sound volume.
This value is the amount of change that will be applied to
`now-playing--volume' by the commands `now-playing-increase-volume' and
`now-playing-decrease-volume'."
  :type 'integer
  :group 'now-playing)

(defcustom now-playing-poll-interval
  200
  "Poll interval (or period) in seconds.

This variable is used by `now-playing-start-polling-current-track' set
the period of polling. Note that changing this value requires a polling
restart."
  :type 'integer
  :group 'now-playing)

(defconst now-playing--osascript-music-init
  '("tell" "application" "\"Music\"" "to")
  "Music app osascript command initializer.")


;;; Functions

(defun now-playing-osascript (arg)
  "Run osascript with ARG."
  (interactive "sOSAScript: ")
  (now-playing--osascript arg))

(defun now-playing--osascript (arg)
  "Process ARG with OSAscript."
  (process-lines "osascript" "-e" arg))

(defun now-playing--run-clause (clause &optional osascript)
  "Execute CLAUSE.

- CLAUSE : Music app command clause.
- OSASCRIPT : if non-nil, then shell out to ‘osascript’, otherwise
  use `ns-do-applescript'."
  (let* ((cmdlist (append now-playing--osascript-music-init clause))
         (cmd (string-join cmdlist " ")))

    (if osascript
        (process-lines "osascript" "-e" cmd)
    (list (ns-do-applescript cmd)))))

(defun now-playing-set-state ()
  "Set Music app playback state.

This command will set the next state given the current state."
  (interactive)
  (let* ((state (now-playing--player-state)))
    (cond
     ((string-equal state "playing") (now-playing-pause))
     ((string-equal state "paused") (now-playing-play))
     ((string-equal state "stopped") (now-playing-play))
     (t                                 ; unknown state - throw playpause at it
      (now-playing-playpause)))))

;;;###autoload (autoload 'now-playing-playpause "now-playing" nil t)
(defun now-playing-playpause ()
  "Toggle play or pause Music app."
  (interactive)
  (let ((clause '("playpause")))
    (now-playing--run-clause clause)))

;;;###autoload (autoload 'now-playing-play "now-playing" nil t)
(defun now-playing-play ()
  "Play Music app.

Note if there is no current track, this AppleScript command will not
succeed. If this occurs, switch to the Music app to directly select a
track to play."
  (interactive)
  (let ((clause '("play")))
    (now-playing--run-clause clause)))

;; (defun now-playing-play-first ()
;;   "Play Music app.

;; Note if there is no current track,

;; Note if the playback state is ‘stopped’, this AppleScript command may
;; not succeed. If this occurs, switch to the Music app and directly
;; select a track."
;;   (interactive)

;;   (if now-playing--current-track-cache
;;       (let* ((track (car (string-split now-playing--current-track-cache " • ")))
;;              ;; (clause (list "play" "track" (format "\"%s\"" track)))
;;              (clause (list "play" "first" "track" "of" "playlist"))
;;              )
;;         (now-playing--run-clause clause))
;;     (error "Unable to play: Open Music app and select track to play")))

;;;###autoload (autoload 'now-playing-pause "now-playing" nil t)
(defun now-playing-pause ()
  "Pause Music app."
  (interactive)
  (let ((clause '("pause")))
    (now-playing--run-clause clause)))

;;;###autoload (autoload 'now-playing-stop "now-playing" nil t)
(defun now-playing-stop ()
  "Stop Music app.

Note this command will deselect the current track in the Music app,
making the commands `now-playing-play' and `now-playing-playpause'
ineffective. If this occurs, switch to the Music app and select a track
to resume expected behavior."
  (interactive)
  (let ((clause '("stop")))
    (now-playing--run-clause clause)))

;;;###autoload (autoload 'now-playing-next-track "now-playing" nil t)
(defun now-playing-next-track ()
  "Next track Music app."
  (interactive)
  (let ((clause '("next" "track")))
    (now-playing--run-clause clause)))

;;;###autoload (autoload 'now-playing-previous-track "now-playing" nil t)
(defun now-playing-previous-track ()
  "Previous track Music app."
  (interactive)
  (let ((clause '("previous" "track")))
    (now-playing--run-clause clause)))

(defun now-playing-get-volume ()
  "Get Music app sound volume."
  (interactive)
  (let* ((clause '("get" "sound" "volume"))
         (result (now-playing--run-clause clause))
         (volume (car result)))
    (setq now-playing--volume volume)
    volume))

(defun now-playing-set-volume (arg)
  "Set Music app sound volume to ARG."
  (interactive "nSet Volume (0-100): ")
  (let* ((clause '("set" "sound" "volume" "to"))
         (clause (append clause (list (number-to-string arg)))))
    (setq now-playing--volume arg)
    (now-playing--run-clause clause)
    (message "Sound Volume: %d" arg)))

;;;###autoload (autoload 'now-playing-increase-volume "now-playing" nil t)
(defun now-playing-increase-volume ()
  "Increase Music app sound volume."
  (interactive)
  (let* ((current-volume (now-playing-get-volume))
         (new-volume (+ current-volume now-playing-volume-delta))
         (volume (cond
                  ((<= new-volume 100) new-volume)
                  ((> new-volume 100) 100))))
    (now-playing-set-volume volume)))

;;;###autoload (autoload 'now-playing-decrease-volume "now-playing" nil t)
(defun now-playing-decrease-volume ()
  "Decrease Music app sound volume."
  (interactive)
  (let* ((current-volume (now-playing-get-volume))
         (new-volume (- current-volume now-playing-volume-delta))
         (volume (cond
                  ((>= new-volume 0) new-volume)
                  ((< new-volume 0) 0))))
    (now-playing-set-volume volume)))

(defun now-playing--current-track ()
  "Get current track on Music app."

  (condition-case err
      (let* ((clause '("name" "of" "current" "track"
                       "&" "\" • \""
                       "&" "artist" "of" "current" "track"
                       "&" "\" • \""
                       "&" "album" "of" "current" "track"))
             (result (car (now-playing--run-clause clause))))
        (if result
            (setq now-playing--current-track-cache result))
        result)

    (error
     (setq now-playing--current-track-cache nil)
     "No track selected - Please open Music app to select a track")))

;;;###autoload (autoload 'now-playing-current-track "now-playing" nil t)
(defun now-playing-current-track ()
  "Get current track on Music app."
  (interactive)
  (let ((track (now-playing--current-track)))
    (if track
        (message "Now Playing: %s" track)
      (message "No track playing"))))

(defun now-playing--player-state ()
  "Get Music app player state."
  (let* ((clause '("get" "player" "state"))
         (result (car (now-playing--run-clause clause t))))
    result))

(defun now-playing-launch-music ()
  "Launch Music app."
  (interactive)
  (process-lines "open" "-a" "Music"))

(defun now-playing--tmenu-refresh ()
  "Refresh menu."
  (interactive)
  (transient--show))



;;; Polling

(defun now-playing-current-track-log ()
  "Get current track on Music app."
  (interactive)
  (let* ((track (now-playing--current-track))
         (ts (format-time-string "[%Y-%m-%d %H:%M:%S %Z]"))
         (msg (format "%s Now Playing: %s" ts track))
         (buf (get-buffer-create "*now playing log*")))
    (when track
      (message msg)
      (unless (string-equal track now-playing--current-track-log)
        (setq now-playing--current-track-log track)
        (with-current-buffer buf
          (setq buffer-read-only t)
          (goto-char (point-max))
          (let ((inhibit-read-only t))
            (insert (concat msg "\n"))))))))

(defun now-playing-is-polling-p ()
  "Predicate if logging the current track."
  (if now-playing--poll-timer
      t
    nil))

;;;###autoload (autoload 'now-playing-find-log "now-playing" nil t)
(defun now-playing-find-log ()
  "Find *now playing log* buffer."
  (interactive)
  (let ((buf (get-buffer "*now playing log*")))
    (if buf
        (progn
          (switch-to-buffer buf)
          (setq buffer-read-only t))
      (message "No *now playing log* buffer"))))

;;;###autoload (autoload 'now-playing-start-polling-current-track "now-playing" nil t)
(defun now-playing-start-polling-current-track ()
  "Poll current track with period `now-playing-poll-interval'.

The history log of played tracks is stored in the special buffer
“*now playing log*”."
  (interactive)
  (if (now-playing-is-polling-p)
      (message "Already polling current track")
    (setq now-playing--poll-timer
          (run-at-time nil
                       now-playing-poll-interval
                       #'now-playing-current-track-log))))

;;;###autoload (autoload 'now-playing-cancel-polling "now-playing" nil t)
(defun now-playing-cancel-polling ()
  "Cancel poll timer."
  (interactive)
  (if (not (now-playing-is-polling-p))
      (message "Not polling current track")
    (cancel-timer now-playing--poll-timer)
    (setq now-playing--poll-timer nil)
    (message "Cancelled track polling")))


;;; Transient

;;;###autoload (autoload 'now-playing-tmenu "now-playing" nil t)
(transient-define-prefix now-playing-tmenu ()
  "Now playing Transient menu for macOS Music app."
  :refresh-suffixes t
  ["Now Playing"
   :class transient-row
   :description (lambda () (format "Now Playing: %s"
                              (let ((track (now-playing--current-track)))
                                (if track
                                    track
                                  ""))))
   ("p" "⏮" now-playing-previous-track :transient t)
   ("SPC" "Play/Pause" now-playing-set-state
    :description (lambda ()
                   (let* ((state (now-playing--player-state)))
                     (cond
                      ((string-equal state "playing") "⏸")
                      ((string-equal state "paused") "▶")
                      ((string-equal state "stopped") "▶")
                      (t "Unknown"))))
    :transient nil)

   ("n" "⏭" now-playing-next-track :transient t)
   ("<up>" "+" now-playing-increase-volume :transient t)
   ("<down>" "−" now-playing-decrease-volume :transient t)
   ("r" "⟲" now-playing--tmenu-refresh :transient t)
   ("o" "♫" now-playing-launch-music)
   ("RET" "Dismiss" transient-quit-all)])

(provide 'now-playing)
;;; now-playing.el ends here
