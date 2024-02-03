class Cobalt.BlueShiftBoardsShowController
    initialize: () ->
        @setupCostarLink()
        @setupBluebotRollupLink()


    setupCostarLink: () ->
        $(document).off 'click', '#blue_shift_board_price_table'
        $(document).on 'click', '#blue_shift_board_price_table', (e) =>
            $target = $(e.target)
            window.open "/costar_market_data", "_self"

    setupBluebotRollupLink: () ->
        $(document).off 'click', '#blue_shift_board_people_table'
        $(document).on 'click', '#blue_shift_board_people_table', (e) =>
            $target = $(e.target)
            window.open "/bluebot_rollup_report", "_self"

            