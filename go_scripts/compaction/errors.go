package compaction

const (
	ErrViewThresholdPercentageTooLow  = "err_view_threshold_percentage_too_low"
	ErrViewThresholdPercentageTooHigh = "err_view_threshold_percentage_too_high"
	ErrFromHourTooHigh                = "err_from_hour_too_high"
	ErrFromMinuteTooHigh              = "err_from_minute_too_high"
	ErrToHourTooHigh                  = "err_to_hour_too_high"
	ErrToMinuteTooHigh                = "err_to_minute_too_high"
	ErrAbortOutsideOnEmptyFrame       = "err_abort_outside_on_empty_frame"
	ErrCannotUnsetCompaction          = "err_cannot_unset_compaction"
	ErrCannotUpdateCompaction         = "err_cannot_update_compaction"
	ErrTimeFrameWithNoThreshold       = "err_time_frame_with_no_threshold"
)
