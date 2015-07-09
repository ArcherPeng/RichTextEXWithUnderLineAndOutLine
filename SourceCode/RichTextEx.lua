--[[
-------------------------------------------------
    RichTextEx.lua
    Created by liangX on 15-04-10.
    Fixed by ArcherPeng on 15-07-02.
-------------------------------------------------
一个简单的富文本 Label，用法
	
	local txt = RichTextEx:create() -- 或 RichTextEx:create(26, cc.c3b(10, 10, 10))
	txt:setText("<#333>你\t好<#800>\n\t&lt;世界&gt;<img temp.png><img_50*50 temp.png><33bad_fmt<#555><64>Big<#077><18>SMALL<")
	-- 多行模式要同时设置 ignoreContentAdaptWithSize(false) 和 contentSize
	txt:setMultiLineMode(true)	-- 这行其实就是 ignoreContentAdaptWithSize(false)
	txt:setContentSize(200, 400)
	addChild(txt)
	
	如果字符串是由用户输入的话，建议调用RichTextEx.htmlEncode("<ABC>")将用户输入内容编码一下，以避免用户输入关键字符导致无法预知的错误
	在生成字符串之前会自动调用RichTextEx.htmlDecode,如果你自定义了字符串创建，请记得调用这个，以解码

基本选项是
	<#F00> = <#FF0000> 	= 文字颜色
	<32>				= 字体大小
	<font Arial>		= 文字字体 支持TTF
	<img filename>		= 图片（filename 可以是已经在 SpriteFrameCache 里的 key，或磁盘文件）
	<img_32*32 fname> 	= 指定大小的图片
	<+2> <-2> <*2> </2> = 当前字体大小 +-*/
	<!>					= 颜色、字体和字体大小恢复默认
	\n \t 				= 换行 和 tab，可能暂时实现得不是很好

	--下边功能需要更换ArcherPeng修改过的RichText！
	<outLine 1>			= 设置1像素描边，只支持TTF字体
	<underLine true>	= 是否开启下划线
	
示例选项是 (在 RichTextEx.defaultCb 中提供)
	<blink 文字>		= （动画）闪烁那些文字
	<rotate 文字>		= （动画）旋转那些文字
	<scale 文字>		= （动画）缩放那些文字
	(但如果你做了 setText(t, callback) 除非你在 callback 主动调用 defaultCb，否则以上选项会被忽略)	
	
TODO 或自己自行可扩展
	<img_w*h http://path/image> 从网络下载图片
	...
	
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

ArcherPeng FixedLog:
	1.修复Create时候tolua的报错
	2.加入自定义字体的功能
--]]

--/////////////////////////////////////////////////////////////////////////////

local _M = class("RichTextEx", function(...)
		return ccui.RichText:create(...)

end)


--/////////////////////////////////////////////////////////////////////////////
local str_sub	= string.sub
local str_rep	= string.rep
local str_byte	= string.byte
local str_gsub	= string.gsub
local str_find	= string.find

local str_trim	= function(input)
	input = str_gsub(input, "^[ \t\n\r]+", "")
	return str_gsub(input, "[ \t\n\r]+$", "")
end

local C_AND		= str_byte("&")
local P_BEG		= str_byte("<")
local P_END		= str_byte(">")
local SHARP		= str_byte("#")
local ULINE		= str_byte("_")
local C_LN		= str_byte("\n")
local C_TAB		= str_byte("\t")
local C_RST		= str_byte("!")
local C_INC		= str_byte("+")
local C_DEC		= str_byte("-")
local C_MUL		= str_byte("*")
local C_DIV		= str_byte("/")

local function c3b_to_c4b(c3b)
	return { r = c3b.r, g = c3b.g,  b = c3b.b, a = 255 }
end

--------------------------------------------------------------------------------
-- #RRGGBB/#RGB to c3b
local function c3b_parse(s)
	local r, g, b = 0, 0, 0
	if #s == 4 then
		r, g, b = 	tonumber(str_rep(str_sub(s, 2, 2), 2), 16),
					tonumber(str_rep(str_sub(s, 3, 3), 2), 16),
					tonumber(str_rep(str_sub(s, 4, 4), 2), 16)
	elseif #s == 7 then
		r, g, b = 	tonumber(str_sub(s, 2, 3), 16),
					tonumber(str_sub(s, 4, 5), 16),
					tonumber(str_sub(s, 6, 7), 16)
	end
	return cc.c3b(r, g, b)
end

--------------------------------------------------------------------------------
-- local _FIX = {
-- 	["&lt;"] = "<",
-- 	["&gt;"] = ">",
-- }
-- local function str_fix(s)
-- 	for k, v in pairs(_FIX) do
-- 		s = str_gsub(s, k, v)
-- 	end
-- 	return s
-- end

--/////////////////////////////////////////////////////////////////////////////
function _M:ctor(fontSize, textColor)
	self._text			= ""
	self._fontSizeDef	= fontSize or 26
	self._textColorDef	= textColor or cc.c3b(11, 11, 11)
	self._fontSize		= self._fontSizeDef
	self._textColor		= self._textColorDef
	self._elements		= {}
	self._textFont 		= ""
	self._outLine 		= 0
	self._underLine 	= false
	
end

--/////////////////////////////////////////////////////////////////////////////
-- 多行模式，要设置 ignoreContentAdaptWithSize(false) 和设置 setContentSize()
function _M:setMultiLineMode(b)
	self:ignoreContentAdaptWithSize(not b)
	return self
end

--/////////////////////////////////////////////////////////////////////////////
function _M.defaultCb(text, sender)
	local BLINK		= "blink "
	local ROTATE	= "rotate "
	local SCALE		= "scale "
	
	if str_sub(text, 1, #BLINK) == BLINK then
		local lbl = ccui.Text:create(self:htmlDecode(str_sub(text, #BLINK + 1)), "", sender._fontSize)
		lbl:setTextColor(c3b_to_c4b(sender._textColor))
		lbl:runAction(cc.RepeatForever:create(cc.Blink:create(10, 10)))
		return lbl
	elseif str_sub(text, 1, #ROTATE) == ROTATE then
		local lbl = ccui.Text:create(self:htmlDecode(str_sub(text, #ROTATE + 1)), "", sender._fontSize)
		lbl:setTextColor(c3b_to_c4b(sender._textColor))
		lbl:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.1, 5)))
		return lbl
	elseif str_sub(text, 1, #SCALE) == SCALE then
		local lbl = ccui.Text:create(self:htmlDecode(str_sub(text, #SCALE + 1)), "", sender._fontSize)
		lbl:setTextColor(c3b_to_c4b(sender._textColor))
		lbl:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.ScaleTo:create(1.0, 0.1), cc.ScaleTo:create(1.0, 1.0))))
		return lbl
	end
	
	return nil
end

--/////////////////////////////////////////////////////////////////////////////
-- TODO: 对 http:// 开头的路径进行动态网络下载
function _M.defaultImgCb(text)
	local w, h = 0, 0
	if str_byte(text, 1) == ULINE then
		local p1 = str_find(text, "*")
		local p2 = str_find(text, " ")
		
		if p1 and p2 and p2 > p1 then
			w = tonumber(str_sub(text, 2, p1 - 1))
			h = tonumber(str_sub(text, p1 + 1, p2))
		end
		
		if p2 then
			text = str_trim(str_sub(text, p2 + 1))
		end
	end
	
	local spf, img = cc.SpriteFrameCache:getInstance():getSpriteFrame(text), nil
	if spf then
--		img = cc.Sprite:createWithSpriteFrame(spf)
		img = ccui.ImageView:create(text, ccui.TextureResType.plistType)
	elseif cc.FileUtils:getInstance():isFileExist(text) then
--	  	img = cc.Sprite:create(text)
		img = ccui.ImageView:create(text, ccui.TextureResType.localType)
	end

	if img and w and h and w > 0 and h > 0 then
		img:ignoreContentAdaptWithSize(false) -- cc.Sprite can't do this, so we use ccui.ImageView
		img:setContentSize(cc.size(w, h))
	end
	
	return img
end

--/////////////////////////////////////////////////////////////////////////////
function _M:addCustomNode(node)
	if node then
		local anc = node:getAnchorPoint()
		if anc.x ~= 0.0 or anc.y ~= 0.0 then
			local tmp = node
			local siz = node:getContentSize()
			node = cc.Node:create()
			node:setContentSize(siz)
			node:addChild(tmp)
			tmp:setPosition(cc.p(siz.width * anc.x, siz.height * anc.y))
		end
		local obj = ccui.RichElementCustomNode:create(0, cc.c3b(255,255,255), 255, node)
		self:pushBackElement(obj)
		self._elements[#self._elements + 1] = obj
	end
end

--/////////////////////////////////////////////////////////////////////////////
-- 可以在 callback 里添加各种自定义<XXXXX XXX>语法控制
function _M:setText(text, callback)
	assert(text)

	self._text = text
	self._callback = callback or self.defaultCb
	
	self._fontSize	= self._fontSizeDef
	self._textColor	= self._textColorDef
	
	-- clear
	for _, lbl in pairs(self._elements) do
		self:removeElement(lbl)
	end
	self._elements = {}

	local p, i, b, c = 1, 1, false
	local str, len, chr, obj = "", #text
	
	while i <= len do
		c = str_byte(text, i)
		if c == P_BEG then	-- <
			if (not b) and (i > p) then
				str = str_sub(text, p, i - 1)
				obj = ccui.RichElementText:create(0, self._textColor, 255, self:htmlDecode(str), self._textFont, self._fontSize,self._outLine,self._underLine)
				self:pushBackElement(obj)
				self._elements[#self._elements + 1] = obj
			end
			
			b = true; p = i + 1; i = p
			
			while i < len do
				if str_byte(text, i) == P_END then	-- >
					b = false
					if i > p then
						str = str_trim(str_sub(text, p, i - 1))
						chr = str_byte(str, 1)
						if chr == SHARP and (#str == 4 or #str == 7) and tonumber(str_sub(str, 2), 16) then -- textColor
							self._textColor = c3b_parse(str)
						elseif chr == C_RST and #str == 1 then	-- reset
							self._textColor = self._textColorDef
							self._fontSize  = self._fontSizeDef
							self._textFont  = ""
							self._outLine = 0
							self._underLine = false 
						elseif (chr == C_INC or chr == C_DEC or chr == C_MUL or chr == C_DIV)
								and tonumber(str_sub(str, 2)) then
							local v = tonumber(str_sub(str, 2)) or 0
							if chr == C_INC then
								self._fontSize = self._fontSize + v
							elseif chr == C_DEC then
								self._fontSize = self._fontSize - v
							elseif chr == C_MUL then
								self._fontSize = self._fontSize * v
							elseif v ~= 0 then
								self._fontSize = self._fontSize / v
							end
						elseif tonumber(str) then	-- fontSize
							self._fontSize = tonumber(str)
						elseif str_sub(str, 1, 5) == "font " or str_sub(str, 1, 5) == "font_" then
							self._textFont = str_trim(str_sub(str, 5, i - 1))
						elseif str_sub(str, 1, 8) == "outLine " or str_sub(str, 1, 8) == "outLine_" then
							local strTemp = str_trim(str_sub(str, 8, i - 1))
							self._outLine = tonumber(strTemp)
						elseif str_sub(str, 1, 10) == "underLine " or str_sub(str, 1, 10) == "underLine_" then 
							local strTemp = str_trim(str_sub(str, 10, i - 1)) 
							if strTemp == "true" then
								self._underLine = true
							else
								self._underLine = false
							end
							
						elseif str_sub(str, 1, 4) == "img " or str_sub(str, 1, 4) == "img_" then
							self:addCustomNode(self.defaultImgCb(str_trim(str_sub(str, 4, i - 1))))
						elseif self._callback then
							self:addCustomNode(self._callback(str, self))
						end
					end
					
					break
				end
				i = i + 1
			end
			
			p = i + 1
		elseif c == C_LN or c == C_TAB then
			if (not b) and (i > p) then
				str = str_sub(text, p, i - 1)
				obj = ccui.RichElementText:create(0, self._textColor, 255, self:htmlDecode(str), self._textFont, self._fontSize,self._outLine,self._underLine)
				self:pushBackElement(obj)
				self._elements[#self._elements + 1] = obj
			end

			obj = cc.Node:create()
			if c == C_LN then
				obj:setContentSize(cc.size(self:getContentSize().width, 1))
			else
				obj:setContentSize(cc.size(self._fontSize * 2, 1))
			end
			self:addCustomNode(obj)


			p = i + 1
		end
		
		i = i + 1
	end

	if (not b) and (p <= len) then
		str = str_sub(text, p)
		obj = ccui.RichElementText:create(0, self._textColor, 255, self:htmlDecode(str), self._textFont, self._fontSize,self._outLine,self._underLine)
		self:pushBackElement(obj)
		self._elements[#self._elements + 1] = obj
	end

	return self
end
function _M:setDefaultFont(font)
	self._textFont = font
end


--[[--

将特殊字符转为 HTML 转义符

~~~ lua

print(RichTextEx.htmlEncode("<ABC>"))
-- 输出 &lt;ABC&gt;

~~~

@param string input 输入字符串

@return string 转换结果


本来想直接把触控的function里边的算法扳过来，发现不对，也不知道哪个二货写的算法。也许是我看的哪个function版本太低了
对于<>  编码成 &lt; &gt; 这个很正常，然后他又把&gt;的&给编码成&amp;
<ABC> 期望的编码结果  "&lt;ABC&gt;"  最终让他给编成了 "&amp;lt;ABC&amp;gt;" 解析时候就出错了。。。。
]]

function _M.htmlEncode(self,input)
	if not input then input = self end
	input = string.gsub(input,"&", "&amp;") 
    input = string.gsub(input,"\"", "&quot;")
    input = string.gsub(input,"'", "&#039;")
    input = string.gsub(input,"<", "&lt;")
    input = string.gsub(input,">", "&gt;")
    return input
end

--[[--

将 HTML 转义符还原为特殊字符，功能与 string.htmlEncode() 正好相反

~~~ lua

print(RichTextEx.htmlDecode("&lt;ABC&gt;"))
-- 输出 <ABC>

~~~

@param string input 输入字符串

@return string 转换结果

]]
function _M.htmlDecode(self,input)
	if not input then input = self end
    input = string.gsub(input,"&gt;",">")
    input = string.gsub(input,"&lt;","<")
    input = string.gsub(input,"&#039;","'")
    input = string.gsub(input,"&quot;","\"")
    input = string.gsub(input,"&amp;","&")
    return input
end
function _M:create(...)
	local richTextEx = _M.new(...)
    return richTextEx
end

--/////////////////////////////////////////////////////////////////////////////

return _M

