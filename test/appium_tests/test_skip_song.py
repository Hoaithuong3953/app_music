import unittest
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
import time

class SkipSongTest(unittest.TestCase):
    def setUp(self):
        desired_caps = {
            "platformName": "Android",
            "deviceName": "emulator-5554",  # Đổi thành ID thiết bị của bạn nếu dùng điện thoại thật
            "appPackage": "com.example.app",  # Đổi thành package của ứng dụng
            "appActivity": ".MainActivity",  # Đổi thành activity chính
            "automationName": "UiAutomator2"
        }
        self.driver = webdriver.Remote("http://localhost:4723/wd/hub", desired_caps)
        self.driver.implicitly_wait(10)

    def test_skip_song_success(self):
        """Kiểm thử chuyển bài thành công"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/nextButton").click()

        # Kiểm tra tên bài hát sau khi chuyển
        current_song = self.driver.find_element(AppiumBy.ID, "com.example:id/currentSong").text
        self.assertNotEqual(current_song, "Song 1")  # Kiểm tra rằng bài hát đã chuyển
        time.sleep(2)

    def test_skip_song_failure(self):
        """Kiểm thử chuyển bài không thành công (Ví dụ: không có bài hát tiếp theo)"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/nextButton").click()

        # Giả sử ứng dụng sẽ hiển thị thông báo lỗi nếu không có bài hát tiếp theo
        error_message = self.driver.find_element(AppiumBy.ID, "com.example:id/errorMessage").text
        self.assertEqual(error_message, "Không còn bài hát tiếp theo.")
        time.sleep(2)

    def tearDown(self):
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()
