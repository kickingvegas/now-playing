;;; now-playing-test-utils.el --- Now Playing Test Utils           -*- lexical-binding: t; -*-

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
(require 'seq)
(require 'ert)
(require 'now-playing)

(defun npt-mock-run-clause (fn)
  "Mock FN to just compute the command string."
  (cl-letf (((symbol-function 'now-playing-get-volume)
             (lambda ()
               25))

            ((symbol-function 'now-playing--run-clause)
             (lambda (clause)
               (let* ((cmdlist (append now-playing--osascript-music-init clause))
                      (cmd (string-join cmdlist " ")))
                 cmd))))

    (funcall fn)))

(defun npt-check-command (fn control)
  "Check that FN issues the correct OSAScript command with CONTROL."
  (should (string-equal (npt-mock-run-clause fn) control)))

(provide 'now-playing-test-utils)
;;; now-playing-test-utils.el ends here
