# RichTextEX支持下划线和描边的版本(用于Cocos2d-x)  
## 这个是干什么的
将如下文字内容  
`"<#F37C2A><font Helvetica><30>【世】<#3AB5B3><underLine true>寒江孤叶<underLine false><#F8F4D7>:HelloWorld"`  
生成如图所示样式的RichText(**支持图片以及闪烁、旋转和其他自定义的效果、控件**)  
  
 <img src="https://raw.githubusercontent.com/ArcherPeng/RichTextEXWithUnderLineAndOutLine/master/06C0BE26-17B5-4753-9729-D909E2099FB2.png" width = "439" height = "53" alt="示例图片" align=center />
## 关于它
这个是LUA版本的，CPP版本的没写，欢迎移植CPP和JS版本  
LUA文件是用一个别人写的文件修改的（添加一些功能，修复几个BUG……话说之前跑都跑不起来啊亲……什么鬼）   
另外抱歉，找不到他的Github链接了……  
***·****TTF字体支持描边，系统字体是不支持的*
## 使用说明  
RichTextEx使用起来非常简单，只要将RichTextEx.lua复制到你的项目目录中，并require它就可以了  
比如这样：  

    APUtils = APUtils or {}  
    APUtils.RichTextEx = APUtils.RichTextEx or require("APUtils/gui/RichTextEx.lua")

使用RichText来创建一个富文本是非常简单的： 

  	local txt = RichTextEx:create() -- 或 RichTextEx:create(26, cc.c3b(10, 10, 10))
  	txt:setText("<outLine 5><underLine true><#EFB65C><font res/fonts/pw.ttf><24>您的元宝和银券不足请<#FF0000><35>充值<#EFB65C><24>,或领取抽取元宝奖励！")
  	-- 多行模式要同时设置 ignoreContentAdaptWithSize(false) 和 contentSize
  	txt:setMultiLineMode(true)	-- 这行其实就是 ignoreContentAdaptWithSize(false)
  	txt:setContentSize(200, 400)
  	someNode:addChild(txt)
	
***如果字符串是由用户输入的话，建议调用`RichTextEx.htmlUnicode("<ABC>")`将用户输入内容编码一下，以避免用户输入关键字符导致无法预知的错误***  
**在生成字符串之前会自动调用RichTextEx.htmlDecode,如果你自定义了用于显示文字内容的控件，请记得调用它，以对字符串进行解码**   
###RichTextEx的基本选项

    <#F00> = <#FF0000> 	= 文字颜色
  	<32>				= 字体大小
  	<font Arial>		= 文字字体 支持TTF
  	<img filename>		= 图片（filename 可以是已经在 SpriteFrameCache 里的 key，或磁盘文件）
  	<img_32*32 fname> 	= 指定大小的图片
  	<+2> <-2> <*2> </2> = 当前字体大小 +-*/
  	<!>					= 颜色、字体和字体大小恢复默认
  	\n \t 				= 换行 和 tab，可能暂时实现得不是很好 最好不要用 如果需要换行你可以创建多个RichText然后依次放好
  	<outLine 1>			= 设置1像素描边，只支持TTF字体
  	<underLine true>	= 是否开启下划线
###RichTextEx的示例选项 (在 RichTextEx.defaultCb 中提供)   
  	<blink 文字>		= （动画）闪烁那些文字
  	<rotate 文字>		= （动画）旋转那些文字
  	<scale 文字>		= （动画）缩放那些文字
  	(但如果你做了 setText(t, callback) 除非你在 callback 主动调用 defaultCb，否则以上选项会被忽略)	
	
###你可以对功能进行扩展  
	`<img_w*h http://path/image> 例如从网络下载图片`
	
同时支持自定义特殊语法，加入 callback 回调就可，如  
	
  	txt:setText("XXXXX <aaaa haha> <bbbb> <CCCC> xxx", function(text, sender) -- 第二个参数 sender 可选
  		-- 对每一个自定义的 <***> 都会调用此 callback
  		-- text 就等于 *** (不含<>)
  		-- 简单的返回一个 Node 的子实例就可，如
  		-- 如果接收第二个参数 sender，就可获取当前文字大小、颜色: sender._fontSize、sender._textColor
  		
  		if string.sub(text, 1, 4) == "aaaa" then
  			return ccui.Text:create("aaa111" .. string.sub(text, 6)), "", 32)
  			--这里如果为了代码的健壮性最好加入self:htmlDecode
  			--return ccui.Text:create(self:htmlDecode("aaa111" .. string.sub(text, 6))), "", 32)
  		elseif text == "bbbb" then
  			-- 用当前文字大小和颜色
  			local lbl = ccui.Text:create("bbb111", "", sender._fontSize)
  			lbl:setTextColor(sender._textColor)
  			return lbl
  		elseif string.sub(text, 1, 4) == "CCCC" then
  			local img = ccui.ImageView:create(....)
  			img:setScale(...)
  			img:runAction(...)
  			return img
  		end
  	end)

## 你还要做什么  
***为了支持描边和下划线还要修改一下Cocos的源码***  
UIRichText.h和UIRichText.cpp放到项目源码目录 替换原来的  
路径:frameworks/cocos2d-x/cocos/ui  
(修改内容主要三个方面：加入下划线设置，加入描边设置，RichText可以自动更改高度了)  
另外还需要修改toLua文件  
frameworks/cocos2d-x/cocos/scripting/lua-bindings/auto/lua_cocos2dx_ui_auto.cpp  
18878行左右能看到两个函数  
int lua_cocos2dx_ui_RichElementText_init(lua_State* tolua_S)  
和  
int lua_cocos2dx_ui_RichElementText_create(lua_State* tolua_S)  
将这两个函数的实现替换为如下形式：  

    int lua_cocos2dx_ui_RichElementText_init(lua_State* tolua_S)
    {
        int argc = 0;
        cocos2d::ui::RichElementText* cobj = nullptr;
        bool ok  = true;
    
    #if COCOS2D_DEBUG >= 1
        tolua_Error tolua_err;
    #endif
    
    
    #if COCOS2D_DEBUG >= 1
        if (!tolua_isusertype(tolua_S,1,"ccui.RichElementText",0,&tolua_err)) goto tolua_lerror;
    #endif
    
        cobj = (cocos2d::ui::RichElementText*)tolua_tousertype(tolua_S,1,0);
    
    #if COCOS2D_DEBUG >= 1
        if (!cobj) 
        {
            tolua_error(tolua_S,"invalid 'cobj' in function 'lua_cocos2dx_ui_RichElementText_init'", nullptr);
            return 0;
        }
    #endif
    
        argc = lua_gettop(tolua_S)-1;
        if (argc == 8)
        {
            int arg0;
            cocos2d::Color3B arg1;
            uint16_t arg2;
            std::string arg3;
            std::string arg4;
            double arg5;
            int arg6;
            bool arg7;
    
            ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "ccui.RichElementText:init");
    
            ok &= luaval_to_color3b(tolua_S, 3, &arg1, "ccui.RichElementText:init");
    
            ok &= luaval_to_uint16(tolua_S, 4,&arg2, "ccui.RichElementText:init");
    
            ok &= luaval_to_std_string(tolua_S, 5,&arg3, "ccui.RichElementText:init");
    
            ok &= luaval_to_std_string(tolua_S, 6,&arg4, "ccui.RichElementText:init");
    
            ok &= luaval_to_number(tolua_S, 7,&arg5, "ccui.RichElementText:init");
            
            ok &= luaval_to_int32(tolua_S, 8,&arg6, "ccui.RichElementText:init");
            
            ok &= luaval_to_boolean(tolua_S, 9,&arg7, "ccui.RichElementText:init");
            if(!ok)
            {
                tolua_error(tolua_S,"invalid arguments in function 'lua_cocos2dx_ui_RichElementText_init'", nullptr);
                return 0;
            }
            bool ret = cobj->init(arg0, arg1, arg2, arg3, arg4, arg5,arg6,arg7);
            tolua_pushboolean(tolua_S,(bool)ret);
            return 1;
        }
        luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d \n", "ccui.RichElementText:init",argc, 6);
        return 0;
    
    #if COCOS2D_DEBUG >= 1
        tolua_lerror:
        tolua_error(tolua_S,"#ferror in function 'lua_cocos2dx_ui_RichElementText_init'.",&tolua_err);
    #endif
    
        return 0;
    }
    int lua_cocos2dx_ui_RichElementText_create(lua_State* tolua_S)
    {
        int argc = 0;
        bool ok  = true;
    
    #if COCOS2D_DEBUG >= 1
        tolua_Error tolua_err;
    #endif
    
    #if COCOS2D_DEBUG >= 1
        if (!tolua_isusertable(tolua_S,1,"ccui.RichElementText",0,&tolua_err)) goto tolua_lerror;
    #endif
    
        argc = lua_gettop(tolua_S) - 1;
    
        if (argc == 6)
        {
            int arg0;
            cocos2d::Color3B arg1;
            uint16_t arg2;
            std::string arg3;
            std::string arg4;
            double arg5;
            ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "ccui.RichElementText:create");
            ok &= luaval_to_color3b(tolua_S, 3, &arg1, "ccui.RichElementText:create");
            ok &= luaval_to_uint16(tolua_S, 4,&arg2, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 5,&arg3, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 6,&arg4, "ccui.RichElementText:create");
            ok &= luaval_to_number(tolua_S, 7,&arg5, "ccui.RichElementText:create");
            if(!ok)
            {
                tolua_error(tolua_S,"invalid arguments in function 'lua_cocos2dx_ui_RichElementText_create'", nullptr);
                return 0;
            }
            cocos2d::ui::RichElementText* ret = cocos2d::ui::RichElementText::create(arg0, arg1, arg2, arg3, arg4, arg5);
            object_to_luaval<cocos2d::ui::RichElementText>(tolua_S, "ccui.RichElementText",(cocos2d::ui::RichElementText*)ret);
            return 1;
        }
        if (argc == 7)
        {
            int arg0;
            cocos2d::Color3B arg1;
            uint16_t arg2;
            std::string arg3;
            std::string arg4;
            double arg5;
            int arg6;
            ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "ccui.RichElementText:create");
            ok &= luaval_to_color3b(tolua_S, 3, &arg1, "ccui.RichElementText:create");
            ok &= luaval_to_uint16(tolua_S, 4,&arg2, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 5,&arg3, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 6,&arg4, "ccui.RichElementText:create");
            ok &= luaval_to_number(tolua_S, 7,&arg5, "ccui.RichElementText:create");
            ok &= luaval_to_int32(tolua_S, 8,&arg6, "ccui.RichElementText:create");
            if(!ok)
            {
                tolua_error(tolua_S,"invalid arguments in function 'lua_cocos2dx_ui_RichElementText_create'", nullptr);
                return 0;
            }
            cocos2d::ui::RichElementText* ret = cocos2d::ui::RichElementText::create(arg0, arg1, arg2, arg3, arg4, arg5, arg6);
            object_to_luaval<cocos2d::ui::RichElementText>(tolua_S, "ccui.RichElementText",(cocos2d::ui::RichElementText*)ret);
            return 1;
        }
        if (argc == 8)
        {
            int arg0;
            cocos2d::Color3B arg1;
            uint16_t arg2;
            std::string arg3;
            std::string arg4;
            double arg5;
            int arg6;
            bool arg7;
            ok &= luaval_to_int32(tolua_S, 2,(int *)&arg0, "ccui.RichElementText:create");
            ok &= luaval_to_color3b(tolua_S, 3, &arg1, "ccui.RichElementText:create");
            ok &= luaval_to_uint16(tolua_S, 4,&arg2, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 5,&arg3, "ccui.RichElementText:create");
            ok &= luaval_to_std_string(tolua_S, 6,&arg4, "ccui.RichElementText:create");
            ok &= luaval_to_number(tolua_S, 7,&arg5, "ccui.RichElementText:create");
            ok &= luaval_to_int32(tolua_S, 8,&arg6, "ccui.RichElementText:create");
            ok &= luaval_to_boolean(tolua_S, 9,&arg7, "ccui.RichElementText:create");
            if(!ok)
            {
                tolua_error(tolua_S,"invalid arguments in function 'lua_cocos2dx_ui_RichElementText_create'", nullptr);
                return 0;
            }
            cocos2d::ui::RichElementText* ret = cocos2d::ui::RichElementText::create(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
            object_to_luaval<cocos2d::ui::RichElementText>(tolua_S, "ccui.RichElementText",(cocos2d::ui::RichElementText*)ret);
            return 1;
        }
        luaL_error(tolua_S, "%s has wrong number of arguments: %d, was expecting %d\n ", "ccui.RichElementText:create",argc, 6);
        return 0;
    #if COCOS2D_DEBUG >= 1
        tolua_lerror:
        tolua_error(tolua_S,"#ferror in function 'lua_cocos2dx_ui_RichElementText_create'.",&tolua_err);
    #endif
        return 0;
    }  
重新编译一下项目，然后就可以在项目里用了  
##下个版本要更新的内容  
1.继续修改Cocos2d-x的RichText的源码，使其更好的支持tab和换行  
2.加入可点击的文字，以及点击后变色  
3.为系统字体加入描边(判断为系统字体时，描边采用阴影替代)  
下划线实现的非常拙略，如果你有更好的方法一定要告诉我。  
***欢迎交流QQ:446569365***
