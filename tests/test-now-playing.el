;;; tests-now-playing.el --- Now-Playing Tests -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Charles Choi

;; Author: Charles Choi <kickingvegas@gmail.com>
;; Keywords: tools

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

;;

;;; Code:

(require 'now-playing-test-utils)

(ert-deftest test-now-playing-playpause ()
  "Test for `now-playing-playpause'."
  (let ((control "tell application \"Music\" to playpause"))
    (npt-check-command #'now-playing-playpause control)))

(ert-deftest test-now-playing-play ()
  "Test for `now-playing-play'."
  (let ((control "tell application \"Music\" to play"))
    (npt-check-command #'now-playing-play control)))

(ert-deftest test-now-playing-pause ()
  "Test for `now-playing-pause'."
  (let ((control "tell application \"Music\" to pause"))
    (npt-check-command #'now-playing-pause control)))

(ert-deftest test-now-playing-stop ()
  "Test for `now-playing-stop'."
  (let ((control "tell application \"Music\" to stop"))
    (npt-check-command #'now-playing-stop control)))

(ert-deftest test-now-playing-next-track ()
  "Test for `now-playing-next-track'."
  (let ((control "tell application \"Music\" to next track"))
    (npt-check-command #'now-playing-next-track control)))

(ert-deftest test-now-playing-previous-track ()
  "Test for `now-playing-previous-track'."
  (let ((control "tell application \"Music\" to previous track"))
    (npt-check-command #'now-playing-previous-track control)))

(ert-deftest test-now-playing-get-volume ()
  "Test for `now-playing-get-volume'."
  (let ((control "tell application \"Music\" to get sound volume"))
    (npt-check-clause '("get" "sound" "volume") control)))

(ert-deftest test-now-playing-set-volume ()
  "Test for `now-playing-set-volume'."
  (let ((control "tell application \"Music\" to set sound volume to 24"))
    (npt-check-clause '("set" "sound" "volume" "to" "24") control)))

(ert-deftest test-now-playing--current-track ()
  "Test for `now-playing--current-track'."

  (let ((control "tell application \"Music\" to name of current track \
& \" • \" \
& artist of current track \
& \" • \" \
& album of current track"))
    (npt-check-clause '("name" "of" "current" "track"
                       "&" "\" • \""
                       "&" "artist" "of" "current" "track"
                       "&" "\" • \""
                       "&" "album" "of" "current" "track")
                      control)))

(ert-deftest test-now-playing--player-state ()
  "Test for `now-playing--player-state'."
  (let ((control "tell application \"Music\" to get player state"))
    (npt-check-clause '("get" "player" "state") control)))


(ert-deftest test-now-playing-bin-volume ()
  "Test for `now-playing-bin-volume'."

  (let ((test-data '((0.01 " ")
                     (0.05 "_")
                     (0.125 "▁")
                     (0.25  "▂")
                     (0.375  "▃")
                     (0.5  "▄")
                     (0.625  "▆")
                     (0.75  "▇")
                     (0.875 "█")
                     (-1.0 "?")
                     (1.1 "?"))))
    (mapc (lambda (kp)
            (let* ((level (nth 0 kp))
                   (control (nth 1 kp))
                   (experiment (now-playing-bin-volume level)))

              (should (string-equal experiment control))))
          test-data)))

(provide 'tests-now-playing)
;;; tests-now-playing.el ends here
