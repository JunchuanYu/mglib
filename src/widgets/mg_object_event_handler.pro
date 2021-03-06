; docformat = 'rst'

;+
; Generic event handler for writing object widget programs. `XMANAGER` will not
; allow methods to be called via the `EVENT_HANDLER` keyword. To get around
; this:
;
;   * Specify `EVENT_HANDLER='mg_object_event_handler'` as a keyword to
;     `XMANAGER` (don't automatically if you inherit from `MGwidObjectWidget`).
;   * Put the object widget's reference in the TLB's `UVALUE`.
;   * Write a `handle_events` method in your object widget.
;
; :Params:
;   event : in, required, type=structure
;     events for all widgets generating events in the widget hierarchy
;-
pro mg_object_event_handler, event
  compile_opt strictarr

  widget_control, event.top, get_uvalue=object_widget
  object_widget->handle_events, event
end
