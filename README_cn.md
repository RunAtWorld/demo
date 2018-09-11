# 外部服务调用手册
## 如何使用
> 这里以 用户程序为一个输出 `hello`  的 [python 程序](./customer.py)为例
### 1. 将 `out_service.sh` 放到用户程序目录下
### 2. 将当前目录的所有文件打成 `zip` 压缩包，如 `out_service.zip` 
### 3. 将 `out_service.zip` 上传至 DataIDE 平台，步骤如下： 
  【登录】 => 【数据集成】 => 【数据开发套件】 => 【资源管理】 => 【新建资源】  => 上传 `out_service.zip`
  【数据开发套件】 => 【任务开发】 => 【新建任务流】 => 输入任务名称 => 选择目录
### 4. 启动任务
具体步骤如图：
![](./pic1.jpg)

解释：  
a. 【**选择任务流**】   
b. 【**选择 `SHELL` 组件**】  
c. 【**编写 执行脚本**】  
![](./pic2.jpg)	   
在 `run_task` 中输入用户程序启动命令，如本例子中用户程序为 `customer.py`, 输入： \
```
sh out_service.sh ${service_url} ${instance_id} ${command}
```
d. 【**配置 参数**】    
	按照上图的样例配置， 设置以下 3 个参数。参数说明：  
	- **service_url="http://172.20.101.141:8185/uploadservice"**  : 服务 http 地址    
	- **instance_id**  : 实例 ID，此项无需设置，由系统在上下文中获得    
	- **command="python customer.py"**  ： 用户程序的启动命令    

e. 【**发布任务**】     
f. 【**预跑任务**】     

### 5. 查看任务运行情况
【主菜单】 => 【数据运维】 => 【预跑实例】   
1. 【**选择任务实例**】   
    ![](./pic51.jpg)  
2. 【**查看实例执行信息**】	  
    ![](./pic52.jpg)    
3. 【**查看实例执行日志详情**】	  
    ![](./pic53.jpg)  
