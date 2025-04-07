import unittest
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
import time

class PlayPauseMusicTest(unittest.TestCase):
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

    def test_play_music_success(self):
        """Kiểm thử phát nhạc thành công"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/playButton").click()

        # Kiểm tra trạng thái phát nhạc
        music_status = self.driver.find_element(AppiumBy.ID, "com.example:id/musicStatus").text
        self.assertEqual(music_status, "Đang phát")
        time.sleep(2)

    def test_pause_music_success(self):
        """Kiểm thử dừng nhạc thành công"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/playButton").click()  # Phát nhạc
        self.driver.find_element(AppiumBy.ID, "com.example:id/pauseButton").click()  # Dừng nhạc

        # Kiểm tra trạng thái nhạc đã dừng
        music_status = self.driver.find_element(AppiumBy.ID, "com.example:id/musicStatus").text
        self.assertEqual(music_status, "Đã dừng")
        time.sleep(2)

    def test_play_music_failure(self):
        """Kiểm thử phát nhạc không thành công (Ví dụ nhạc bị lỗi)"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/playButton").click()

        # Giả sử ứng dụng sẽ hiển thị thông báo lỗi nếu không thể phát nhạc
        error_message = self.driver.find_element(AppiumBy.ID, "com.example:id/errorMessage").text
        self.assertEqual(error_message, "Không thể phát nhạc.")
        time.sleep(2)

    def tearDown(self):
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()
