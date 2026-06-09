# Copyright (c) 2024 The ZMK Contributors
# SPDX-License-Identifier: MIT

if(CONFIG_ZMK_BEHAVIOR_INPUT_TAP)
  target_sources(app PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src/behaviors/behavior_input_tap.c)
endif()
