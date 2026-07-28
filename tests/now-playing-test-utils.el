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

(defun npt-mock-run-command (fn)
  "Mock FN to run CLAUSE."
  (cl-letf (((symbol-function 'process-lines)
             (lambda (program &rest args)
               (let* ((cmdlist (append (list program) args)))
                 cmd)))

            ((symbol-function 'ns-do-applescript)
             (lambda (program)
               program)))

    (funcall fn)))

(defun npt-mock-run-clause (clause)
  "Mock FN to run CLAUSE."
  (cl-letf (((symbol-function 'process-lines)
             (lambda (program &rest args)
               (let* ((cmdlist (append (list program) args)))
                 cmd)))

            ((symbol-function 'ns-do-applescript)
             (lambda (program)
               program)))

    (now-playing--run-clause clause)))

(defun npt-check-command (fn control)
  "Check that FN issues the correct OSAScript command with CONTROL."
  (should (string-equal (car (npt-mock-run-command fn)) control)))

(defun npt-check-clause (clause control)
  "Test CLAUSE in `now-playing--run-clause' with CONTROL."
  (should (string-equal (car (npt-mock-run-clause clause)) control)))

(provide 'now-playing-test-utils)
;;; now-playing-test-utils.el ends here
