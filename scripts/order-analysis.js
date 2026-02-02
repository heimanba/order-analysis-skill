
var params = {};
// 这里从浏览器 Copy as fetch 过来，可以做一些修改，比如添加 参数，处理返回值
var result = fetch("https://inner.example.com/api/order-analysis", {
  "headers": {
    "accept": "*/*",
    "accept-language": "zh-CN,zh;q=0.9",
    "content-type": "application/x-www-form-urlencoded",
    "priority": "u=1, i",
    "sec-ch-ua": "\"Google Chrome\";v=\"143\", \"Chromium\";v=\"143\", \"Not A(Brand\";v=\"24\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"macOS\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin"
  },
  "body": "params="+encodeURIComponent(JSON.stringify(params)),
  "method": "POST",
  "mode": "cors",
  "credentials": "include"
});

result
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return response.json();
  })
  .then(data => {
    if (data && data.data) {
      // TODO: 转换数据为AI更容易理解的格式
      return data.data;
    }
    
    console.log('工单数据获取成功:', data);
    return data;
  })
  .catch(error => {
    console.error('获取工单数据失败:', error);
  });