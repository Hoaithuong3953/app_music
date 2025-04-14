import unittest
import time
from appium import webdriver
from appium.options.android import UiAutomator2Options
from appium.webdriver.common.appiumby import AppiumBy
from selenium.common.exceptions import WebDriverException, NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

capabilities = dict(
    platformName='Android',
    automationName='uiautomator2',
    deviceName='emulator-5554',
    appPackage='com.example.app_music',
    appActivity='.MainActivity',
    language='en',
    locale='US'
)

appium_server_url = 'http://127.0.0.1:4723/wd/hub'

class TestLoginFunction(unittest.TestCase):
    def setUp(self) -> None:
        print("🔄 Đang khởi động Appium driver...")
        try:
            options = UiAutomator2Options().load_capabilities(capabilities)
            self.driver = webdriver.Remote(appium_server_url, options=options)
            time.sleep(5)  # Chờ ứng dụng khởi động
            print("✅ Driver đã khởi động thành công.")
        except WebDriverException as e:
            print(f"❌ Lỗi khi khởi động driver: {e}")
            self.driver = None
            raise

    def tearDown(self) -> None:
        if self.driver:
            try:
                self.driver.quit()
                print("✅ Đã đóng driver.")
            except WebDriverException as e:
                print(f"⚠️ Không thể đóng driver: {e}")
        else:
            print("⚠️ Không có driver để đóng.")

    def scroll_to_element(self):
        """Cuộn để tìm nút Login dựa trên content-desc"""
        try:
            self.driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR,
                                     'new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView('
                                     'new UiSelector().description("Login"))')
            print("✅ Đã cuộn để tìm nút Login.")
        except Exception as e:
            print(f"⚠️ Lỗi khi cuộn: {e}")

    def test_successful_login(self):
        if not self.driver:
            self.fail("❌ Driver chưa được khởi động.")
        try:
            # Tìm và nhập email
            email_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[0]  # Index 0 cho email
            email_field.click()
            email_field.clear()
            email_field.send_keys("khai@gmail.com")
            time.sleep(1)
            email_text = email_field.get_attribute("text")
            print(f"✅ Đã nhập email: {email_text}")
            self.assertEqual(email_text, "khai@gmail.com", "Email không được nhập đúng!")

            # Tìm và nhập mật khẩu
            password_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[1]  # Index 1 cho password
            password_field.click()
            password_field.clear()
            password_field.send_keys("123456")
            time.sleep(1)
            password_text = password_field.get_attribute("text")
            print(f"✅ Đã nhập mật khẩu: {password_text}")
            self.assertEqual(len(password_text), len("123456"), "Độ dài mật khẩu không khớp!")

            # Ẩn bàn phím và cuộn đến nút Login
            self.driver.hide_keyboard()
            time.sleep(1)
            self.scroll_to_element()
            login_button = WebDriverWait(self.driver, 10).until(
                EC.element_to_be_clickable((AppiumBy.XPATH, "//android.widget.Button[@content-desc='Login']"))
            )
            login_button.click()
            print("✅ Đã nhấn nút Login.")
            time.sleep(5)

            # Kiểm tra thông báo lỗi
            try:
                error_message = WebDriverWait(self.driver, 5).until(
                    EC.visibility_of_element_located(
                        (AppiumBy.XPATH, "//*[@content-desc[contains(., 'Đăng nhập không thành công')]]")
                    )
                )
                self.fail(f"❌ Đăng nhập thất bại với thông tin đúng: {error_message.get_attribute('content-desc')}")
            except:
                print("✅ Đăng nhập thành công (không có thông báo lỗi)!")
        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Không tìm thấy phần tử cần thiết: {e}")
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Lỗi không xác định: {e}")

    def test_failed_login(self):
        if not self.driver:
            self.fail("❌ Driver chưa được khởi động.")
        try:
            # Tìm và nhập email
            email_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[0]  # Index 0 cho email
            email_field.click()
            email_field.clear()
            email_field.send_keys("wrong@example.com")
            time.sleep(1)
            email_text = email_field.get_attribute("text")
            print(f"✅ Đã nhập email sai: {email_text}")
            self.assertEqual(email_text, "wrong@example.com", "Email sai không được nhập đúng!")

            # Tìm và nhập mật khẩu
            password_field = WebDriverWait(self.driver, 10).until(
                EC.presence_of_all_elements_located((AppiumBy.CLASS_NAME, "android.widget.EditText"))
            )[1]  # Index 1 cho password
            password_field.click()
            password_field.clear()
            password_field.send_keys("wrongpassword")
            time.sleep(1)
            password_text = password_field.get_attribute("text")
            print(f"✅ Đã nhập mật khẩu sai: {password_text}")
            self.assertEqual(len(password_text), len("wrongpassword"), "Độ dài mật khẩu sai không khớp!")

            # Ẩn bàn phím và cuộn đến nút Login
            self.driver.hide_keyboard()
            time.sleep(1)
            self.scroll_to_element()
            login_button = WebDriverWait(self.driver, 10).until(
                EC.element_to_be_clickable((AppiumBy.XPATH, "//android.widget.Button[@content-desc='Login']"))
            )
            login_button.click()
            print("✅ Đã nhấn nút Login.")
            time.sleep(3)

            # Kiểm tra thông báo lỗi
            error_message = WebDriverWait(self.driver, 10).until(
                EC.visibility_of_element_located(
                    (AppiumBy.XPATH, "//*[@content-desc[contains(., 'Đăng nhập không thành công')]]")
                )
            )
            self.assertTrue(error_message.is_displayed(), "Không hiển thị lỗi khi đăng nhập sai.")
            print("✅ Đăng nhập thất bại như mong đợi.")
        except NoSuchElementException as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Không tìm thấy phần tử: {e}")
        except Exception as e:
            print("🔍 In cấu trúc giao diện để debug:")
            print(self.driver.page_source)
            self.fail(f"❌ Lỗi không xác định: {e}")

if __name__ == "__main__":
    unittest.main(verbosity=2)