import unittest
from appium import webdriver
from appium.webdriver.common.appiumby import AppiumBy
import time

class SearchMusicTest(unittest.TestCase):
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

    def test_search_success(self):
        """Kiểm thử tìm kiếm bài hát thành công"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/searchButton").click()
        self.driver.find_element(AppiumBy.ID, "com.example:id/searchInput").send_keys("Shape of You")
        self.driver.find_element(AppiumBy.ID, "com.example:id/searchConfirmButton").click()

        # Kiểm tra kết quả tìm kiếm
        search_result = self.driver.find_element(AppiumBy.ID, "com.example:id/searchResult").text
        self.assertIn("Shape of You", search_result)
        time.sleep(2)

    def test_search_failure_no_result(self):
        """Kiểm thử tìm kiếm bài hát không thành công (Không tìm thấy kết quả)"""
        self.driver.find_element(AppiumBy.ID, "com.example:id/searchButton").click()
        self.driver.find_element(AppiumBy.ID, "com.example:id/searchInput").send_keys("NonExistentSong")
        self.driver.find_element(AppiumBy.ID, "com.example:id/searchConfirmButton").click()

        # Kiểm tra thông báo không có kết quả
        error_message = self.driver.find_element(AppiumBy.ID, "com.example:id/noResultMessage").text
        self.assertEqual(error_message, "Không tìm thấy bài hát.")
        time.sleep(2)

    def tearDown(self):
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()
