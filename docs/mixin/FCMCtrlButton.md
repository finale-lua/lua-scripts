# FCMCtrlButton

## Disabled Methods
As `FCCtrlButton` inherits from `FCCtrlCheckbox`, the following methods have been disabled from `FCMCtrlCheckbox`:
- `AddHandleCheckChange`
- `RemoveHandleCheckChange`

To handle button presses, use `AddHandleCommand`, inherited from `FCMControl`.
