;; ========================
;; QuickMarker - Main
;; ========================

(vl-load-com)

(setq *qm-main-file* (findfile "quickmarker.lsp"))

(if *qm-main-file*
  (setq *qm-base-path* (vl-filename-directory *qm-main-file*))
  (setq *qm-base-path* nil)
)

(defun qm:load-local-file (fname / fullpath)
  (if *qm-base-path*
    (progn
      (setq fullpath (strcat *qm-base-path* "\\" fname))
      (if (findfile fullpath)
        (load fullpath)
        (princ (strcat "\nНе найден файл: " fullpath))
      )
    )
    (princ "\nНе удалось определить путь к quickmarker.lsp")
  )
)

(qm:load-local-file "qm-config.lsp")
(qm:load-local-file "qm-lib.lsp")

(defun qm:qmark-process (ent net_rain net_sewer net_water settings
                           / is_sewer is_water
                             start_num reverse_order mode_DR mode_outlet do_pipes
                             mat_idx diam_idx futl_idx meth_idx start_pk
                             net_info prefix is_grate is_outlet net_code layer_wells layer_pipes
                             pipe_text method_text pts pt_count last_idx methods_lst
                             i num pt next_pt ang offset_pt text_str
                             cum_dist mid_pt seg_ang seg_len seg_len_str full_text)
  (setq is_sewer (= net_sewer "1"))
  (setq is_water (= net_water "1"))

  (setq start_num     (cdr (assoc 'start-num settings)))
  (setq reverse_order (cdr (assoc 'reverse-order settings)))
  (setq mode_DR       (cdr (assoc 'mode-DR settings)))
  (setq mode_outlet   (cdr (assoc 'mode-outlet settings)))
  (setq do_pipes      (cdr (assoc 'do-pipes settings)))
  (setq mat_idx       (cdr (assoc 'mat-idx settings)))
  (setq diam_idx      (cdr (assoc 'diam-idx settings)))
  (setq futl_idx      (cdr (assoc 'futl-idx settings)))
  (setq meth_idx      (cdr (assoc 'meth-idx settings)))
  (setq start_pk      (cdr (assoc 'start-pk settings)))

  (setq net_info (qm:build-network-settings is_sewer is_water mode_DR mode_outlet))
  (setq prefix      (nth 0 net_info))
  (setq is_grate    (nth 1 net_info))
  (setq is_outlet   (nth 2 net_info))
  (setq net_code    (nth 3 net_info))
  (setq layer_wells (nth 4 net_info))
  (setq layer_pipes (nth 5 net_info))

  (qm:save-run-state
    net_rain net_sewer net_water is_sewer is_water settings
    prefix is_grate is_outlet net_code layer_wells layer_pipes
  )

  (setq pipe_text (qm:build-pipe-text is_sewer is_water mat_idx diam_idx futl_idx))
  (setq methods_lst (qm:get-methods-by-net is_sewer is_water))
  (setq method_text (qm:safe-nth meth_idx methods_lst))
  (setq pts (qm:get-poly-points ent))

  (if (null pts)
    (princ *qm-msg-no-vertices*)
    (progn
      (if reverse_order
        (setq pts (reverse pts))
      )

      (setq pt_count (length pts))
      (setq last_idx (1- pt_count))

      (qm:apply-predefined-styles)
      (qm:create-layer layer_wells net_code)

      (setq i 0)
      (setq num start_num)
      (if (and is_water (not is_outlet))
        (setq cum_dist (* start_pk 100.0))
        (setq cum_dist 0.0)
      )

      (foreach pt pts
  (if (or (and (not is_grate) (not is_outlet))
          (< i last_idx))
    (progn
      (setq text_str (qm:get-text-by-vertex is_water is_outlet prefix num cum_dist))
      (if (or (not is_water) is_outlet)
        (setq num (1+ num))
      )
      (setq ang (qm:get-angle-at-point pts i pt_count))
      (setq offset_pt (qm:get-offset-point pt ang i))
      (qm:add-mleader pt offset_pt text_str nil)
    )
  )

  (if (< i last_idx)
    (setq cum_dist (+ cum_dist (distance pt (nth (1+ i) pts))))
  )
  (setq i (1+ i))
)

      (if (and do_pipes pipe_text (/= pipe_text ""))
        (progn
          (qm:create-layer layer_pipes net_code)
          (setq i 0)
          (while (< i last_idx)
            (setq pt (nth i pts))
            (setq next_pt (nth (1+ i) pts))
            (setq mid_pt (polar pt (angle pt next_pt) (/ (distance pt next_pt) 2.0)))
            (setq seg_ang (angle pt next_pt))
            (setq offset_pt (qm:get-offset-point mid_pt seg_ang i))
            (setq seg_len (qm:round-to-half (distance pt next_pt)))
            (setq seg_len_str (qm:fmt1 seg_len))
            (setq full_text (strcat pipe_text ", L= " seg_len_str " м, " method_text))
            (qm:add-mleader mid_pt offset_pt full_text *qm-pipe-width*)
            (setq i (1+ i))
          )
        )
      )

      (princ *qm-msg-done*)
    )
  )
)

(defun c:QMARK (/ *error* old_osmode old_cmdecho old_layer old_textstyle old_mleaderstyle
                  ent elist etype net_sel settings need_repeat)
  (defun *error* (msg)
    (qm:safe-restore-var "OSMODE" old_osmode)
    (qm:safe-restore-var "CMDECHO" old_cmdecho)
    (qm:safe-restore-var "CLAYER" old_layer)
    (qm:safe-restore-var "TEXTSTYLE" old_textstyle)
    (qm:safe-restore-var "CMLEADERSTYLE" old_mleaderstyle)
    (if (and msg (not (wcmatch (strcase msg t) "*break,*cancel*,*exit*")))
      (princ (strcat "\nОшибка: " msg))
    )
    (princ)
  )

  (setq old_osmode (getvar "OSMODE"))
  (setq old_cmdecho (getvar "CMDECHO"))
  (setq old_layer (getvar "CLAYER"))
  (setq old_textstyle (getvar "TEXTSTYLE"))
  (setq old_mleaderstyle (getvar "CMLEADERSTYLE"))

  (setvar "CMDECHO" 0)
  (setvar "OSMODE" 0)

  (setq need_repeat T)

  (while need_repeat
    (setq need_repeat nil)
    (setq ent (entsel "\nВыберите полилинию трассы: "))

    (if (not ent)
      (princ *qm-msg-cancel*)
      (progn
        (setq ent (car ent))
        (setq elist (entget ent))
        (setq etype (cdr (assoc 0 elist)))

        (if (not (member etype '("LWPOLYLINE" "POLYLINE")))
          (progn
            (princ *qm-msg-not-polyline*)
            (setq need_repeat T)
          )
          (progn
            (setq net_sel (qm:show-net-dialog))
            (if (null net_sel)
              (princ *qm-msg-cancel*)
              (progn
                (setq settings
                  (qm:show-settings-dialog
                    (= (nth 1 net_sel) "1")
                    (= (nth 2 net_sel) "1")
                  )
                )

                (cond
                  ((null settings)
                    (princ *qm-msg-cancel*)
                  )
                  ((= (car settings) 2)
                    (setq need_repeat T)
                  )
                  (T
                    (qm:qmark-process
                      ent
                      (nth 0 net_sel)
                      (nth 1 net_sel)
                      (nth 2 net_sel)
                      (nth 1 settings)
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
  )

  (qm:safe-restore-var "OSMODE" old_osmode)
  (qm:safe-restore-var "CMDECHO" old_cmdecho)
  (qm:safe-restore-var "CLAYER" old_layer)
  (qm:safe-restore-var "TEXTSTYLE" old_textstyle)
  (qm:safe-restore-var "CMLEADERSTYLE" old_mleaderstyle)
  (princ)
)

(defun c:QDEL (/ ss ss_temp layer_name i)
  (setq ss (ssadd))

  (foreach layer_name *qm-qdel-layers*
    (if (tblsearch "LAYER" layer_name)
      (progn
        (setq ss_temp (ssget "_X" (list (cons 0 "MULTILEADER") (cons 8 layer_name))))
        (if ss_temp
          (progn
            (setq i 0)
            (repeat (sslength ss_temp)
              (ssadd (ssname ss_temp i) ss)
              (setq i (1+ i))
            )
          )
        )
      )
    )
  )

  (if (> (sslength ss) 0)
    (progn
      (command "_.ERASE" ss "")
      (princ (strcat "\nУдалено выносок QuickMarker: " (itoa (sslength ss))))
    )
    (princ *qm-msg-qdel-empty*)
  )

  (princ)
)

(defun c:БМАРК () (c:QMARK))
(defun c:БУДЛ () (c:QDEL))

(princ *qm-msg-loaded*)
(princ)