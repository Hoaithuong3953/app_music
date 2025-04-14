import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import WebDriverException, NoSuchElementException, TimeoutException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Cấu hình capabilities
capabilities = dict(
    platformName='Android',
    automationName='uiautomator2',
    deviceName='emulator-5554',
    appPackage='com.example.app_music',
    appActivity='.MainActivity',
    language='en',
    locale='US',
    newCommandTimeout=300,
    adbExecTimeout=60000,
    appWaitActivity='*',
    noReset=True,
    fullReset=False
)

appium_server_url = 'http://127.0.0.1:4723/wd/hub'

class PlayPauseMusicTest(unittest.TestCase):
    def setUp(self):
        print("🔄 Đang khởi động Appium driver...")
        try:
            options = UiAutomator2Options().load_capabilities(capabilities)
            self.driver = webdriver.Remote(appium_server_url, options=options)
            self.wait = WebDriverWait(self.driver, 20)
            time.sleep(5)  # Chờ ứng dụng khởi động
            print("✅ Driver đã khởi động thành công.")
        except WebDriverException as e:
            print(f"❌ Lỗi khi khởi động driver: {e}")
            self.driver = None
            raise

    def tearDown(self):
        if self.driver:
            try:
                self.driver.quit()
                print("✅ Đã đóng driver.")
            except WebDriverException as e:
                print(f"⚠️ Không thể đóng driver: {e}")
        else:
            print("⚠️ Không có driver để đóng.")

    def scroll_to_element(self, content_desc):
        """Cuộn để tìm phần tử dựa trên content-desc"""
        try:
            self.driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR,
                                     f'new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView('
                                     f'new UiSelector().description("{content_desc}"))')
            print(f"✅ Đã cuộn để tìm phần tử: {content_desc}")
        except Exception as e:
            print(f"⚠️ Lỗi khi cuộn: {e}")

    def test_login_and_search_play(self):
        """Đăng nhập, tìm kiếm bài hát 'Đánh đổi', phát nhạc, nhấn lại bài hát và dừng phát."""
        if not self.driver:
            self.fail("❌ Driver chưa được khởi động.")

        # Bước 1: Đăng nhập
        try:
            print("🔍 Bắt đầu đăng nhập...")
            email_field = self.wait.until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[0]
            email_field.click()
            email_field.clear()
            email_field.send_keys("khai@gmail.com")
            time.sleep(1)
            email_text = email_field.get_attribute("text")
            print(f"✅ Đã nhập email: {email_text}")
            self.assertEqual(email_text, "khai@gmail.com", "Email không được nhập đúng!")

            password_field = self.wait.until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[1]
            password_field.click()
            password_field.clear()
            password_field.send_keys("123456")
            time.sleep(1)
            password_text = password_field.get_attribute("text")
            print(f"✅ Đã nhập mật khẩu: {password_text}")
            self.assertEqual(len(password_text), len("123456"), "Độ dài mật khẩu không khớp!")

            self.driver.hide_keyboard()
            time.sleep(1)
            self.scroll_to_element("Login")
            login_button = self.wait.until(
                EC.element_to_be_clickable((AppiumBy.XPATH, "//android.widget.Button[@content-desc='Login']"))
            )
            login_button.click()
            print("✅ Đã nhấn nút Login.")
            time.sleep(5)

            try:
                error_message = self.wait.until(
                    EC.visibility_of_element_located(
                        (AppiumBy.XPATH, "//*[@content-desc[contains(., 'Đăng nhập không thành công')]]")
                    )
                )
                self.fail(f"❌ Đăng nhập thất bại: {error_message.get_attribute('content-desc')}")
            except TimeoutException:
                print("✅ Đăng nhập thành công (không có thông báo lỗi)!")
        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Không tìm thấy phần tử cần thiết: {e}")
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Lỗi không xác định: {e}")

        # Bước 2: Nhấn vào thanh tìm kiếm và nhập "Đánh đổi"
        try:
            print("🔍 Đang tìm thanh tìm kiếm...")
            search_field = self.wait.until(
                EC.presence_of_element_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )
            search_field.click()
            search_field.clear()
            search_field.send_keys("Đánh đổi")
            time.sleep(2)  # Chờ kết quả tìm kiếm hiển thị
            search_text = search_field.get_attribute("text")
            print(f"✅ Đã nhập từ khóa tìm kiếm: {search_text}")
            self.assertEqual(search_text, "Đánh đổi", "Từ khóa tìm kiếm không được nhập đúng!")
        except TimeoutException:
            print("⚠️ Không tìm thấy thanh tìm kiếm bằng EditText, thử tìm bằng hintText...")
            try:
                search_field = self.wait.until(
                    EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Search music')]"))
                )
                search_field.click()
                search_field.clear()
                search_field.send_keys("Đánh đổi")
                time.sleep(2)
                search_text = search_field.get_attribute("text")
                print(f"✅ Đã nhập từ khóa tìm kiếm: {search_text}")
                self.assertEqual(search_text, "Đánh đổi", "Từ khóa tìm kiếm không được nhập đúng!")
            except TimeoutException as e:
                print("🔍 In cấu trúc giao diện để debug:")
                print(self.driver.page_source)
                self.fail(f"❌ Không tìm thấy thanh tìm kiếm: {e}")

        # Bước 3: Nhấn nút phát bên cạnh bài hát "Đánh đổi" trong kết quả tìm kiếm
        try:
            print("🔍 Đang tìm bài hát 'Đánh đổi' và nút phát...")
            # Tìm bài hát "Đánh đổi"
            song_result = self.wait.until(
                EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Đánh đổi')]"))
            )
            # Tìm nút phát bên cạnh (dùng sibling để tìm IconButton)
            play_button = self.wait.until(
                EC.element_to_be_clickable(
                    (AppiumBy.XPATH, "//*[contains(@text, 'Đánh đổi')]/following-sibling::*[@content-desc='play_song_button']")
                )
            )
            play_button.click()
            print("✅ Đã nhấn nút phát bài hát 'Đánh đổi'.")
            time.sleep(5)  # Chờ nhạc bắt đầu phát
        except TimeoutException:
            print("⚠️ Không tìm thấy bài hát hoặc nút phát.")
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail("❌ Không tìm thấy bài hát hoặc nút phát trong kết quả tìm kiếm.")
        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Không tìm thấy bài hát hoặc nút phát: {e}")

        # Bước 4: Nhấn lại bài hát "Đánh đổi" trong kết quả tìm kiếm
        try:
            print("🔍 Nhấn lại bài hát 'Đánh đổi' để mở NowPlayingScreen...")
            # Tìm lại bài hát "Đánh đổi"
            song_result = self.wait.until(
                EC.presence_of_element_located((AppiumBy.XPATH, "//*[contains(@text, 'Đánh đổi')]"))
            )
            song_result.click()
            print("✅ Đã nhấn lại bài hát 'Đánh đổi'.")
            time.sleep(5)  # Chờ màn hình NowPlayingScreen tải hoàn toàn
        except TimeoutException:
            print("⚠️ Không tìm thấy bài hát 'Đánh đổi' để nhấn lại.")
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail("❌ Không tìm thấy bài hát để nhấn lại.")
        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Không tìm thấy bài hát: {e}")

        # Bước 5: Dừng phát nhạc (nhấn nút tạm dừng trên NowPlayingScreen)
        try:
            print("🔍 Đang tìm nút tạm dừng trên NowPlayingScreen...")
            pause_button = self.wait.until(
                EC.element_to_be_clickable((AppiumBy.ACCESSIBILITY_ID, "pause_button"))
            )
            pause_button.click()
            print("✅ Đã nhấn nút tạm dừng.")
        except TimeoutException:
            print("⚠️ Không tìm thấy nút tạm dừng.")
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail("❌ Không tìm thấy nút tạm dừng trên NowPlayingScreen.")
        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Không tìm thấy nút tạm dừng: {e}")

        # Bước 6: Xác minh trạng thái tạm dừng
        try:
            play_button = self.wait.until(
                EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "play_button"))
            )
            self.assertIsNotNone(play_button, "Không chuyển sang trạng thái tạm dừng.")
            print("✅ Nhạc đã dừng thành công!")
        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Không xác minh được trạng thái tạm dừng: {e}")
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Lỗi không xác định: {e}")

if __name__ == "__main__":
    unittest.main(verbosity=2)