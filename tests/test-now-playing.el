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


(provide 'tests-now-playing)
;;; tests-now-playing.el ends here
