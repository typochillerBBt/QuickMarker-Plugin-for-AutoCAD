;; ========================
;; QuickMarker - Config
;; ========================

(vl-load-com)

(setq *qm-version* "1.1")

(setq *qm-text-style* "RLP")
(setq *qm-mleader-style* "RLP")

(setq *qm-offset-dist* 25.0)
(setq *qm-pipe-width* 85.0)
;; ДК
(setq *qm-materials-rain*
  '(
    "Труба ПП SN8"
    "Труба ПП SN16"
    "Труба ПП SN24"
    "Труба Ростпайп SN16"
    "Труба Ростпайп SN24"
    "Труба ПЭ"
   )
)
;; ГК
(setq *qm-materials-sewer*
  '(
    "Труба ПП SN8"
    "Труба ПП SN16"
    "Труба ПП SN24"
    "Труба Ростпайп SN16"
    "Труба Ростпайп SN24"
    "Труба ПЭ"
   )
)
;; ГВ
(setq *qm-materials-water*
  '(
    "Труба ПЭ100 SDR17"
    "Труба ПЭ100 SDR13.6"
    "Труба ВЧШГ"
    "Труба стальная"
   )
)
;; ДК
(setq *qm-diameters-rain*
  '(
    "DN/ID 487/400"
    "DN/ID 603/500"
    "DN/ID 720/600"
    "DN/ID 964/800"
   )
)
;; ГК
(setq *qm-diameters-sewer*
  '(
    "DN/ID 487/400"
    "DN/ID 603/500"
    "DN/ID 720/600"
    "DN/ID 964/800"
   )
)
;; ГВ
(setq *qm-diameters-water*
  '(
    "Ду100"
    "Ду150"
    "Ду200"
    "Ду250"
    "Ду300"
   )
)
;; ДК
(setq *qm-futlyars-rain*
  '(
    "нет"
    "в ст. ф-ре %%C720x0.00"
    "в ст. ф-ре в изол. усил. типа %%C720x0.00"
    "в ст. ф-ре %%C820x0.00"
    "в ст. ф-ре в изол. усил. типа %%C820x0.00"
    "в ст. ф-ре %%C920x0.00"
    "в ст. ф-ре в изол. усил. типа %%C920x0.00"
    "в ст. ф-ре %%C1220x0.00"
    "в ст. ф-ре в изол. усил. типа %%C1220x0.00"
   )
)
;; ГК
(setq *qm-futlyars-sewer*
  '(
    "нет"
    "в ст. ф-ре %%C720x0.00"
    "в ст. ф-ре в изол. усил. типа %%C720x0.00"
    "в ст. ф-ре %%C820x0.00"
    "в ст. ф-ре в изол. усил. типа %%C820x0.00"
    "в ст. ф-ре %%C920x0.00"
    "в ст. ф-ре в изол. усил. типа %%C920x0.00"
    "в ст. ф-ре %%C1220x0.00"
    "в ст. ф-ре в изол. усил. типа %%C1220x0.00"
   )
)
;; ГВ
(setq *qm-futlyars-water*
  '(
    "нет"
    "в ст. ф-ре %%C325x0.00"
    "в ст. ф-ре %%C426x0.00"
    "в ст. ф-ре %%C530x0.00"
   )
)
;; ДК
(setq *qm-methods-rain*
  '(
    "закрытый способ (бурошнек)"
    "открытый способ"
    "закрытый способ (микротоннелирование)"
   )
)
;; ГК
(setq *qm-methods-sewer*
  '(
    "закрытый способ (бурошнек)"
    "открытый способ"
    "закрытый способ (микротоннелирование)"
   )
)
;; ГВ
(setq *qm-methods-water*
  '(
    "открытый способ"
    "закрытый способ (микротоннелирование)"
    "закрытый способ (бурошнек)"
   )
)

(setq *qm-net-rain-code* "ДК")
(setq *qm-net-sewer-code* "ГК")
(setq *qm-net-water-code* "ГВ")

(setq *qm-layer-rain-wells* "_ДК_ВыноскиКолодцы")
(setq *qm-layer-rain-pipes* "_ДК_ВыноскиТрубы")
(setq *qm-layer-sewer-wells* "_ГК_ВыноскиКолодцы")
(setq *qm-layer-sewer-pipes* "_ГК_ВыноскиТрубы")
(setq *qm-layer-water-pickets* "_ГВ_ВыноскиПикеты")
(setq *qm-layer-water-outlets* "_ГВ_ВыноскиВыпуски")
(setq *qm-layer-water-pipes* "_ГВ_ВыноскиТрубы")

(setq *qm-qdel-layers*
  (list
    *qm-layer-rain-wells*
    *qm-layer-rain-pipes*
    *qm-layer-sewer-wells*
    *qm-layer-sewer-pipes*
    *qm-layer-water-pickets*
    *qm-layer-water-pipes*
    *qm-layer-water-outlets*
  )
)

(setq *qm-msg-loaded*
  "\nQuickMarker 1.1 загружен. Команды:\nQMARK (БМАРК) - Добавление выносок;\nQCSV (БСХР) - Сохранение в формате CSV;\nQDEL (БУДЛ) - Удаление всех созданных выносок."
)

(setq *qm-msg-cancel* "\nОтмена.")
(setq *qm-msg-not-polyline* "\nНе полилиния.")
(setq *qm-msg-no-vertices* "\nНет вершин.")
(setq *qm-msg-done* "\nГотово!")
(setq *qm-msg-no-settings* "\nНет сохранённых параметров QuickMarker. Сначала выполните QMARK.")
(setq *qm-msg-no-markers* "\nВыноски QuickMarker не найдены. Сначала выполните QMARK.")
(setq *qm-msg-no-csv-data* "\nНет данных для экспорта.")
(setq *qm-msg-csv-failed* "\nНе удалось создать CSV-файл.")
(setq *qm-msg-csv-cancel* "\nСохранение CSV отменено.")
(setq *qm-msg-qdel-empty* "\nНе найдено выносок QuickMarker.")

(setq *qm-csv-header-interval* "Интервал")
(setq *qm-csv-header-length*   "Длина, м")
(setq *qm-csv-header-method*   "Способ")
(setq *qm-csv-header-diam*     "Диаметр")
(setq *qm-csv-header-mat*      "Материал")

(princ)