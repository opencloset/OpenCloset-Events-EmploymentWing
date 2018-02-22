# OpenCloset-Events-EmploymentWing #

취업날개 이벤트 기능

- 사용자의 상태를 변경(`update_status`)
  - 예약중
  - 대여완료
  - 회수완료
  - 대여취소
- 사용자의 예약시간을 변경(`update_booking_datetime`)
  - 최초예약과 예약시간변경을 구분해서 호출해야합니다.
