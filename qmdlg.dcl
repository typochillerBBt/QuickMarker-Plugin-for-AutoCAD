netdlg : dialog {
  label = "QuickMarker - Выбор сети";
  width = 40;

  : boxed_radio_column {
    label = "Тип сети:";
    : radio_button {
      key = "net_rain";
      label = "Дождевая канализация";
      value = "1";
    }
    : radio_button {
      key = "net_sewer";
      label = "Хоз. бытовая канализация";
    }
    : radio_button {
      key = "net_water";
      label = "Водопровод";
    }
  }

  spacer;
  ok_cancel;
}

setdlg : dialog {
  label = "Настройки";
  width = 65;

  : boxed_column {
    key = "common_box";
    label = "Общие настройки";
    : toggle {
      key = "reverse";
      label = "Обратная нумерация";
      value = "0";
    }
  }

  : boxed_radio_column {
    key = "rain_mode_box";
    label = "Нумерация (ДК/ГК)";
    : radio_button {
      key = "mode_K";
      label = "Колодцы (К)";
      value = "1";
    }
    : radio_button {
      key = "mode_DR";
      label = "Решётки (ДР)";
    }
  }

  : boxed_radio_column {
    key = "water_mode_box";
    label = "Нумерация (ГВ)";
    : radio_button {
      key = "mode_PK";
      label = "Пикеты";
      value = "1";
    }
    : radio_button {
      key = "mode_outlet";
      label = "Выпуски";
    }
  }

  : boxed_column {
    key = "water_pk_box";
    label = "Настройка пикетов";
    : toggle {
      key = "use_branch";
      label = "Указывать ветку";
      value = "0";
    }
    : edit_box {
      key = "branch_num";
      label = "Номер ветки:";
      edit_width = 10;
      value = "1";
    }
    : edit_box {
      key = "start_pk";
      label = "Стартовый номер пикета:";
      edit_width = 10;
      value = "0";
    }
  }

  : boxed_column {
    label = "Трубы";
    : toggle {
      key = "do_pipes";
      label = "Маркировать трубы";
      value = "1";
    }
    : popup_list {
      key = "material";
      label = "Материал:";
      edit_width = 40;
    }
    : popup_list {
      key = "diametr";
      label = "Диаметр:";
      edit_width = 40;
    }
    : popup_list {
      key = "futlyar";
      label = "Футляр:";
      edit_width = 40;
    }
    : popup_list {
      key = "method";
      label = "Способ прокладки:";
      edit_width = 40;
    }
  }

  spacer;

  : row {
    : button {
      key = "back";
      label = "<< Назад";
      width = 15;
    }
    : button {
      key = "accept";
      label = "OK";
      is_default = true;
      width = 12;
    }
    : button {
      key = "cancel";
      label = "Отмена";
      is_cancel = true;
      width = 12;
    }
  }
}