;; ========================
;; QuickMarker - Library
;; ========================

(vl-load-com)

(setq *qm-state* nil)

(defun qm:state-get (key / pair)
  (setq pair (assoc key *qm-state*))
  (if pair (cdr pair) nil)
)

(defun qm:state-set (key val / pair)
  (setq pair (assoc key *qm-state*))
  (if pair
    (setq *qm-state* (subst (cons key val) pair *qm-state*))
    (setq *qm-state* (cons (cons key val) *qm-state*))
  )
  val
)

(defun qm:safe-restore-var (var val)
  (if (not (null val)) (setvar var val))
)

(defun qm:safe-nth (idx lst)
  (if (and idx lst (>= idx 0) (< idx (length lst))) (nth idx lst) nil)
)

(defun qm:trim (s)
  (if s (vl-string-trim " \t\r\n" s) "")
)

(defun qm:round-to-half (val / ip fr)
  (setq ip (fix val))
  (setq fr (- val ip))
  (cond
    ((< fr 0.25) ip)
    ((<= fr 0.75) (+ ip 0.5))
    (T (+ ip 1.0))
  )
)

(defun qm:fmt1 (val / s)
  (setq s (rtos val 2 1))
  (setq s (vl-string-subst "," "." s))
  (if (not (vl-string-search "," s))
    (setq s (strcat s ",0"))
  )
  s
)

(defun qm:csv-escape (s / txt)
  (if (null s)
    (setq txt "")
    (setq txt s)
  )
  (setq txt (vl-string-subst "\"\"" "\"" txt))
  (strcat "\"" txt "\"")
)

(defun qm:text-style-exists-p (style_name)
  (if (tblsearch "STYLE" style_name) T nil)
)

(defun qm:mleader-style-exists-p (style_name / dict found)
  (setq found nil)
  (if (setq dict (dictsearch (namedobjdict) "ACAD_MLEADERSTYLE"))
    (foreach x dict
      (if (and (= (car x) 3) (= (strcase (cdr x)) (strcase style_name)))
        (setq found T)
      )
    )
  )
  found
)

(defun qm:apply-predefined-styles ()
  (if (qm:mleader-style-exists-p *qm-mleader-style*)
    (setvar "CMLEADERSTYLE" *qm-mleader-style*)
    (princ (strcat "\nВнимание: не найден стиль мультивыноски: " *qm-mleader-style*))
  )
  (if (qm:text-style-exists-p *qm-text-style*)
    (setvar "TEXTSTYLE" *qm-text-style*)
    (princ (strcat "\nВнимание: не найден стиль текста: " *qm-text-style*))
  )
  (princ)
)

(defun qm:get-rgb-by-net (net_code)
  (cond
    ((= net_code *qm-net-water-code*) '(0 0 255))
    ((= net_code *qm-net-sewer-code*) '(127 0 0))
    ((= net_code *qm-net-rain-code*) '(255 127 0))
    (T '(255 255 255))
  )
)

(defun qm:create-layer (name net_code / acad doc layers layer color_obj rgb)
  (setq acad (vlax-get-acad-object))
  (setq doc (vla-get-ActiveDocument acad))
  (setq layers (vla-get-Layers doc))

  (if (tblsearch "LAYER" name)
    (setq layer (vla-Item layers name))
    (progn
      (setq layer (vla-Add layers name))
      (vla-put-LineWeight layer 0)
    )
  )

  (setq rgb (qm:get-rgb-by-net net_code))
  (setq color_obj (vla-GetInterfaceObject acad "AutoCAD.AcCmColor.24"))
  (apply 'vla-SetRGB (cons color_obj rgb))
  (vla-put-TrueColor layer color_obj)
  (vlax-release-object color_obj)

  (setvar "CLAYER" name)
  layer
)

(defun qm:get-poly-points (ent / elist etype pts next_e data)
  (setq elist (entget ent))
  (setq etype (cdr (assoc 0 elist)))
  (setq pts nil)

  (cond
    ((= etype "LWPOLYLINE")
      (foreach item elist
        (if (= (car item) 10)
          (setq pts (append pts (list (cdr item))))
        )
      )
    )
    ((= etype "POLYLINE")
      (setq next_e (entnext ent))
      (while next_e
        (setq data (entget next_e))
        (cond
          ((= (cdr (assoc 0 data)) "VERTEX")
            (setq pts (append pts (list (cdr (assoc 10 data)))))
          )
          ((= (cdr (assoc 0 data)) "SEQEND")
            (setq next_e nil)
          )
        )
        (if next_e
          (setq next_e (entnext next_e))
        )
      )
    )
  )
  pts
)

(defun qm:add-mleader (pt offset_pt text_str text_width / e obj)
  (command "_.MLEADER" pt offset_pt text_str)
  (setq e (entlast))
  (if (and e text_width)
    (progn
      (setq obj (vlax-ename->vla-object e))
      (if obj
        (vlax-put-property obj 'TextWidth text_width)
      )
    )
  )
  e
)

(defun qm:get-angle-at-point (pts i pt_count / pt prev_pt next_pt)
  (cond
    ((<= pt_count 1) 0.0)
    ((= i 0)
      (setq pt (nth 0 pts))
      (setq next_pt (nth 1 pts))
      (angle pt next_pt)
    )
    ((= i (1- pt_count))
      (setq prev_pt (nth (1- i) pts))
      (setq pt (nth i pts))
      (angle prev_pt pt)
    )
    (T
      (setq pt (nth i pts))
      (setq next_pt (nth (1+ i) pts))
      (angle pt next_pt)
    )
  )
)

(defun qm:get-side-sign (idx)
  (if (= (rem idx 2) 0) 1.0 -1.0)
)

(defun qm:get-offset-point (base_pt base_ang idx / side_ang)
  (setq side_ang (+ base_ang (* (qm:get-side-sign idx) (/ pi 2.0))))
  (polar base_pt side_ang *qm-offset-dist*)
)

(defun qm:get-materials-by-net (is_sewer is_water)
  (cond
    (is_water *qm-materials-water*)
    (is_sewer *qm-materials-sewer*)
    (T *qm-materials-rain*)
  )
)

(defun qm:get-diameters-by-net (is_sewer is_water)
  (cond
    (is_water *qm-diameters-water*)
    (is_sewer *qm-diameters-sewer*)
    (T *qm-diameters-rain*)
  )
)

(defun qm:get-futlyars-by-net (is_sewer is_water)
  (cond
    (is_water *qm-futlyars-water*)
    (is_sewer *qm-futlyars-sewer*)
    (T *qm-futlyars-rain*)
  )
)

(defun qm:get-methods-by-net (is_sewer is_water)
  (cond
    (is_water *qm-methods-water*)
    (is_sewer *qm-methods-sewer*)
    (T *qm-methods-rain*)
  )
)

(defun qm:build-pipe-text (is_sewer is_water mat_idx diam_idx futl_idx / mat diam futl txt)
  (setq mat (qm:safe-nth mat_idx (qm:get-materials-by-net is_sewer is_water)))
  (setq diam (qm:safe-nth diam_idx (qm:get-diameters-by-net is_sewer is_water)))
  (setq futl (qm:safe-nth futl_idx (qm:get-futlyars-by-net is_sewer is_water)))
  (setq txt "")
  (if mat (setq txt mat))
  (if diam (setq txt (strcat txt " " diam)))
  (if (and futl (/= futl "нет"))
    (setq txt (strcat txt " " futl))
  )
  txt
)

(defun qm:build-network-settings (is_sewer is_water mode_DR mode_outlet / prefix is_grate is_outlet net_code layer_wells layer_pipes)
  (cond
    (is_water
      (setq is_outlet (= mode_outlet "1"))
      (if is_outlet (setq prefix "Выпуск") (setq prefix "ПК"))
      (setq is_grate nil)
      (setq net_code *qm-net-water-code*)
    )
    (is_sewer
      (setq prefix "К")
      (setq is_grate nil)
      (setq is_outlet nil)
      (setq net_code *qm-net-sewer-code*)
    )
    (T
      (setq is_grate (= mode_DR "1"))
      (setq is_outlet nil)
      (if is_grate (setq prefix "ДР") (setq prefix "К"))
      (setq net_code *qm-net-rain-code*)
    )
  )

  (cond
    ((and is_water is_outlet)
      (setq layer_wells *qm-layer-water-outlets*)
      (setq layer_pipes *qm-layer-water-pipes*)
    )
    (is_water
      (setq layer_wells *qm-layer-water-pickets*)
      (setq layer_pipes *qm-layer-water-pipes*)
    )
    (is_sewer
      (setq layer_wells *qm-layer-sewer-wells*)
      (setq layer_pipes *qm-layer-sewer-pipes*)
    )
    (T
      (setq layer_wells *qm-layer-rain-wells*)
      (setq layer_pipes *qm-layer-rain-pipes*)
    )
  )

  (list prefix is_grate is_outlet net_code layer_wells layer_pipes)
)

(defun qm:get-text-by-vertex (is_water is_outlet prefix num cum_dist / rest_val km rest_str branch_prefix branch_num use_branch)
  (setq use_branch (qm:state-get 'use-branch))
  (setq branch_num (qm:state-get 'branch-num))
  (setq branch_prefix "ПК")

  (if (and is_water use_branch branch_num (> branch_num 0))
    (setq branch_prefix (strcat "ПК{\\A1;\\H0.45x;\\S" (itoa branch_num) "^;}"))
  )

  (cond
    ((and is_water is_outlet)
      (strcat "Выпуск " (itoa num))
    )
    (is_water
      (setq rest_val (qm:round-to-half (rem cum_dist 100.0)))
      (setq km (fix (/ cum_dist 100.0)))
      (if (>= rest_val 100.0)
        (progn
          (setq km (1+ km))
          (setq rest_val 0.0)
        )
      )
      (setq rest_str (qm:fmt1 rest_val))
      (strcat branch_prefix (itoa km) "+" rest_str)
    )
    (T
      (strcat prefix (itoa num))
    )
  )
)

(defun qm:load-dialog-safe (/ dcl_id)
  (setq dcl_id (load_dialog "qmdlg.dcl"))
  (if (or (null dcl_id) (< dcl_id 0))
    nil
    dcl_id
  )
)

(defun qm:show-net-dialog (/ dcl_id user_click net_rain net_sewer net_water result)
  (setq dcl_id (qm:load-dialog-safe))
  (if (null dcl_id)
    (progn
      (princ "\nОшибка загрузки qmdlg.dcl")
      nil
    )
    (progn
      (if (not (new_dialog "netdlg" dcl_id))
        (progn
          (unload_dialog dcl_id)
          (princ "\nНе удалось открыть диалог netdlg.")
          nil
        )
        (progn
          (action_tile "accept"
            "(setq net_rain (get_tile \"net_rain\"))
             (setq net_sewer (get_tile \"net_sewer\"))
             (setq net_water (get_tile \"net_water\"))
             (done_dialog 1)"
          )
          (action_tile "cancel" "(done_dialog 0)")
          (setq user_click (start_dialog))
          (unload_dialog dcl_id)
          (if (= user_click 1)
            (setq result (list net_rain net_sewer net_water))
            (setq result nil)
          )
          result
        )
      )
    )
  )
)

(defun qm:fill-popup (key items / i)
  (start_list key)
  (if items
    (progn
      (setq i 0)
      (repeat (length items)
        (add_list (nth i items))
        (setq i (1+ i))
      )
    )
  )
  (end_list)
)

(defun qm:settings-from-dialog-result (start_num_str reverse_order mode_K mode_DR mode_PK mode_outlet do_pipes mat_sel diam_sel futl_sel meth_sel start_pk_str use_branch branch_num_str)
  (list
    (cons 'start-num (max 1 (atoi start_num_str)))
    (cons 'reverse-order (= reverse_order "1"))
    (cons 'mode-K mode_K)
    (cons 'mode-DR mode_DR)
    (cons 'mode-PK mode_PK)
    (cons 'mode-outlet mode_outlet)
    (cons 'do-pipes (= do_pipes "1"))
    (cons 'mat-idx (atoi mat_sel))
    (cons 'diam-idx (atoi diam_sel))
    (cons 'futl-idx (atoi futl_sel))
    (cons 'meth-idx (atoi meth_sel))
    (cons 'start-pk (max 0 (atoi start_pk_str)))
    (cons 'use-branch (= use_branch "1"))
    (cons 'branch-num (max 1 (atoi branch_num_str)))
  )
)

(defun qm:show-settings-dialog (is_sewer is_water / dcl_id user_click result
                                         reverse_order mode_K mode_DR
                                         mode_PK mode_outlet do_pipes mat_sel diam_sel futl_sel meth_sel
                                         start_pk_str use_branch branch_num_str start_num_str)
  (setq dcl_id (qm:load-dialog-safe))

  (if (null dcl_id)
    (progn
      (princ "\nОшибка загрузки qmdlg.dcl")
      nil
    )
    (progn
      (if (not (new_dialog "setdlg" dcl_id))
        (progn
          (unload_dialog dcl_id)
          (princ "\nНе удалось открыть диалог setdlg.")
          nil
        )
        (progn
          (setq start_num_str "1")

          (set_tile "reverse" "0")
          (set_tile "mode_K" "1")
          (set_tile "mode_PK" "1")
          (set_tile "do_pipes" "1")
          (set_tile "start_pk" "0")
          (set_tile "use_branch" "0")
          (set_tile "branch_num" "1")

          (qm:fill-popup "material" (qm:get-materials-by-net is_sewer is_water))
          (qm:fill-popup "diametr"  (qm:get-diameters-by-net is_sewer is_water))
          (qm:fill-popup "futlyar"  (qm:get-futlyars-by-net is_sewer is_water))
          (qm:fill-popup "method"   (qm:get-methods-by-net is_sewer is_water))

          (set_tile "material" "0")
          (set_tile "diametr" "0")
          (set_tile "futlyar" "0")
          (set_tile "method" "0")

          (cond
            (is_water
              (mode_tile "common_box" 0)
              (mode_tile "rain_mode_box" 1)
              (mode_tile "water_mode_box" 0)
              (mode_tile "water_pk_box" 0)
              (set_tile "mode_PK" "1")
            )
            (is_sewer
              (mode_tile "common_box" 0)
              (mode_tile "rain_mode_box" 0)
              (mode_tile "water_mode_box" 1)
              (mode_tile "water_pk_box" 1)
              (set_tile "mode_K" "1")
            )
            (T
              (mode_tile "common_box" 0)
              (mode_tile "rain_mode_box" 0)
              (mode_tile "water_mode_box" 1)
              (mode_tile "water_pk_box" 1)
              (set_tile "mode_K" "1")
            )
          )

          (if (= (get_tile "use_branch") "1")
            (mode_tile "branch_num" 0)
            (mode_tile "branch_num" 1)
          )

          (action_tile "use_branch"
            "(if (= (get_tile \"use_branch\") \"1\")
               (mode_tile \"branch_num\" 0)
               (mode_tile \"branch_num\" 1)
             )"
          )

          (action_tile "accept"
            "(setq reverse_order (get_tile \"reverse\"))
             (setq mode_K (get_tile \"mode_K\"))
             (setq mode_DR (get_tile \"mode_DR\"))
             (setq mode_PK (get_tile \"mode_PK\"))
             (setq mode_outlet (get_tile \"mode_outlet\"))
             (setq do_pipes (get_tile \"do_pipes\"))
             (setq mat_sel (get_tile \"material\"))
             (setq diam_sel (get_tile \"diametr\"))
             (setq futl_sel (get_tile \"futlyar\"))
             (setq meth_sel (get_tile \"method\"))
             (setq start_pk_str (get_tile \"start_pk\"))
             (setq use_branch (get_tile \"use_branch\"))
             (setq branch_num_str (get_tile \"branch_num\"))
             (done_dialog 1)"
          )
          (action_tile "cancel" "(done_dialog 0)")
          (action_tile "back" "(done_dialog 2)")

          (setq user_click (start_dialog))
          (unload_dialog dcl_id)

          (cond
            ((= user_click 1)
              (setq result
                (list 1
                  (qm:settings-from-dialog-result
                    start_num_str
                    reverse_order
                    mode_K
                    mode_DR
                    mode_PK
                    mode_outlet
                    do_pipes
                    mat_sel
                    diam_sel
                    futl_sel
                    meth_sel
                    start_pk_str
                    use_branch
                    branch_num_str
                  )
                )
              )
            )
            ((= user_click 2)
              (setq result (list 2))
            )
            (T
              (setq result nil)
            )
          )
          result
        )
      )
    )
  )
)

(defun qm:save-run-state (net_rain net_sewer net_water is_sewer is_water settings prefix is_grate is_outlet net_code layer_wells layer_pipes)
  (qm:state-set 'net-rain net_rain)
  (qm:state-set 'net-sewer net_sewer)
  (qm:state-set 'net-water net_water)
  (qm:state-set 'is-sewer is_sewer)
  (qm:state-set 'is-water is_water)
  (foreach pair settings
    (qm:state-set (car pair) (cdr pair))
  )
  (qm:state-set 'prefix prefix)
  (qm:state-set 'is-grate is_grate)
  (qm:state-set 'is-outlet is_outlet)
  (qm:state-set 'net-code net_code)
  (qm:state-set 'layer-wells layer_wells)
  (qm:state-set 'layer-pipes layer_pipes)
  T
)

(defun qm:has-last-settings-p ()
  (and (qm:state-get 'prefix)
       (qm:state-get 'net-code)
       (qm:state-get 'layer-pipes)
       (numberp (qm:state-get 'start-num))
  )
)

(defun qm:get-mleader-text (ename / obj txt)
  (setq txt nil)
  (if ename
    (progn
      (setq obj (vlax-ename->vla-object ename))
      (if obj
        (setq txt (vlax-get-property obj 'TextString))
      )
    )
  )
  txt
)

(defun qm:get-mleader-base-point (ename / ed pt)
  (setq pt nil)
  (if ename
    (progn
      (setq ed (entget ename))
      (setq pt (cdr (assoc 10 ed)))
    )
  )
  pt
)

(defun qm:distance-2d (p1 p2)
  (distance (list (car p1) (cadr p1) 0.0)
            (list (car p2) (cadr p2) 0.0))
)

(defun qm:get-nearest-mleader (pt ss / i ename mlpt best_ent best_dist cur_dist)
  (setq i 0 best_ent nil best_dist nil)
  (repeat (sslength ss)
    (setq ename (ssname ss i))
    (setq mlpt (qm:get-mleader-base-point ename))
    (if mlpt
      (progn
        (setq cur_dist (qm:distance-2d pt mlpt))
        (if (or (null best_dist) (< cur_dist best_dist))
          (setq best_dist cur_dist best_ent ename)
        )
      )
    )
    (setq i (1+ i))
  )
  best_ent
)

(defun qm:normalize-mleader-text (txt)
  (if txt
    (progn
      (setq txt (vl-string-subst " " "\\P" txt))
      (setq txt (vl-string-subst " " "\n" txt))
      (setq txt (vl-string-trim " " txt))
    )
  )
  txt
)

(defun qm:parse-pipe-mleader-text (txt / src first_part dn_pos du_pos diam_short mat_text method_text len_pos)
  (setq src (qm:normalize-mleader-text txt))
  (setq mat_text "" diam_short "" method_text "")

  (if src
    (progn
      (setq len_pos (vl-string-search ", L=" src))
      (if len_pos
        (progn
          (setq first_part (qm:trim (substr src 1 len_pos)))
          (setq method_text (qm:trim (substr src (+ len_pos 8))))
          (if (vl-string-search ", " method_text)
            (setq method_text (qm:trim (substr method_text (+ (vl-string-search ", " method_text) 3))))
          )
        )
        (progn
          (setq first_part src)
          (setq method_text "")
        )
      )

      (setq dn_pos (vl-string-search "DN/ID " first_part))
      (setq du_pos (vl-string-search "Ду" first_part))

      (cond
        (dn_pos
          (setq mat_text (qm:trim (substr first_part 1 dn_pos)))
          (setq diam_short (qm:trim (substr first_part (+ dn_pos 1))))
        )
        (du_pos
          (setq mat_text (qm:trim (substr first_part 1 du_pos)))
          (setq diam_short (qm:trim (substr first_part (+ du_pos 1))))
        )
        (T
          (setq mat_text (qm:trim first_part))
          (setq diam_short "")
        )
      )
    )
  )

  (list method_text diam_short mat_text)
)

(defun qm:get-pipe-mleaders-on-last-layer (/ ss layer_name)
  (setq layer_name (qm:state-get 'layer-pipes))
  (if (and layer_name (tblsearch "LAYER" layer_name))
    (setq ss (ssget "_X" (list (cons 0 "MULTILEADER") (cons 8 layer_name))))
    nil
  )
)

(defun qm:build-interval-last (idx cum_dist pt next_pt / from_label to_label is_water is_outlet prefix start_num)
  (setq is_water (qm:state-get 'is-water))
  (setq is_outlet (qm:state-get 'is-outlet))
  (setq prefix (qm:state-get 'prefix))
  (setq start_num (qm:state-get 'start-num))

  (if (and is_water (not is_outlet))
    (progn
      (setq from_label (qm:get-text-by-vertex is_water is_outlet prefix 0 cum_dist))
      (setq to_label (qm:get-text-by-vertex is_water is_outlet prefix 0 (+ cum_dist (distance pt next_pt))))
    )
    (progn
      (setq from_label (qm:get-text-by-vertex is_water is_outlet prefix (+ start_num idx) 0.0))
      (setq to_label (qm:get-text-by-vertex is_water is_outlet prefix (+ start_num idx 1) 0.0))
    )
  )

  (strcat from_label "-" to_label)
)

(defun qm:collect-csv-row (interval seg_len_str method_text diam_short mat_text)
  (strcat
    (qm:csv-escape interval) ";"
    (qm:csv-escape seg_len_str) ";"
    (qm:csv-escape method_text) ";"
    (qm:csv-escape diam_short) ";"
    (qm:csv-escape mat_text)
  )
)

(defun qm:save-intervals-to-csv (rows / fname f)
  (setq fname
    (getfiled
      "Сохранить CSV для Excel"
      (strcat (getvar "DWGPREFIX") (vl-filename-base (getvar "DWGNAME")) "_intervals.csv")
      "csv"
      1
    )
  )

  (if fname
    (progn
      (setq f (open fname "w"))
      (if f
        (progn
          (write-line
            (strcat
              (qm:csv-escape *qm-csv-header-interval*) ";"
              (qm:csv-escape *qm-csv-header-length*) ";"
              (qm:csv-escape *qm-csv-header-method*) ";"
              (qm:csv-escape *qm-csv-header-diam*) ";"
              (qm:csv-escape *qm-csv-header-mat*)
            ) f)
          (foreach row rows (write-line row f))
          (close f)
          (princ (strcat "\nCSV сохранен: " fname))
        )
        (princ *qm-msg-csv-failed*)
      )
    )
    (princ *qm-msg-csv-cancel*)
  )
)

(defun c:QCSV (/ ss_pipe ent elist etype pts pt_count last_idx
                 i pt next_pt mid_pt seg_len seg_len_str cum_dist
                 nearest_ml ml_text parsed method_text diam_short mat_text
                 interval csv_rows csv_line)
  (if (not (qm:has-last-settings-p))
    (princ *qm-msg-no-settings*)
    (progn
      (setq ss_pipe (qm:get-pipe-mleaders-on-last-layer))
      (if (or (null ss_pipe) (= (sslength ss_pipe) 0))
        (princ *qm-msg-no-markers*)
        (progn
          (setq ent (entsel "\nВыберите полилинию трассы для экспорта CSV: "))
          (if (not ent)
            (princ *qm-msg-cancel*)
            (progn
              (setq ent (car ent))
              (setq elist (entget ent))
              (setq etype (cdr (assoc 0 elist)))
              (if (not (member etype '("LWPOLYLINE" "POLYLINE")))
                (princ *qm-msg-not-polyline*)
                (progn
                  (setq pts (qm:get-poly-points ent))
                  (if (null pts)
                    (princ *qm-msg-no-vertices*)
                    (progn
                      (if (qm:state-get 'reverse-order)
                        (setq pts (reverse pts))
                      )
                      (setq pt_count (length pts))
                      (setq last_idx (1- pt_count))
                      (setq i 0)
                      (setq cum_dist (if (and (qm:state-get 'is-water) (not (qm:state-get 'is-outlet)))
                                       (* (qm:state-get 'start-pk) 100.0)
                                       0.0))
                      (setq csv_rows nil)

                      (while (< i last_idx)
                        (setq pt (nth i pts))
                        (setq next_pt (nth (1+ i) pts))
                        (setq mid_pt (polar pt (angle pt next_pt) (/ (distance pt next_pt) 2.0)))
                        (setq seg_len (qm:round-to-half (distance pt next_pt)))
                        (setq seg_len_str (qm:fmt1 seg_len))
                        (setq interval (qm:build-interval-last i cum_dist pt next_pt))
                        (setq nearest_ml (qm:get-nearest-mleader mid_pt ss_pipe))
                        (setq ml_text (qm:get-mleader-text nearest_ml))
                        (setq parsed (qm:parse-pipe-mleader-text ml_text))
                        (setq method_text (nth 0 parsed))
                        (setq diam_short (nth 1 parsed))
                        (setq mat_text (nth 2 parsed))
                        (setq csv_line (qm:collect-csv-row interval seg_len_str method_text diam_short mat_text))
                        (setq csv_rows (append csv_rows (list csv_line)))
                        (setq cum_dist (+ cum_dist (distance pt next_pt)))
                        (setq i (1+ i))
                      )

                      (if csv_rows
                        (qm:save-intervals-to-csv csv_rows)
                        (princ *qm-msg-no-csv-data*)
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
  )
  (princ)
)

(defun c:БСХР () (c:QCSV))

(princ)