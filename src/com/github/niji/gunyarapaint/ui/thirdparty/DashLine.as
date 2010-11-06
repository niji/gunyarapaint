/**
* 破線描画
* @author nutsu
* @version 0.1
*/

package com.github.niji.gunyarapaint.ui.thirdparty
{
	import flash.display.Graphics;
	import flash.geom.Point;
	
	public class DashLine {
		
		
		//GC
		public var graphics:Graphics;
		
		//破線のサイズ
		public var dashsize:Number;
		public var spacesize:Number;
		private var blocksize:Number;
		
		//前の点
		private var px:Number;
		private var py:Number;
		
		//描画し始める長さ
		private var draw_start:Number;
		
		
		/**
		* コンストラクタ
		*/
		public function DashLine( g:Graphics, size:Number ){
			graphics = g;
			dashsize = spacesize = size;
			blocksize = dashsize + spacesize;
			px = py = 0;
			draw_start = 0.0;
		}
		
		
		/**
		* moveTo
		*/
		public function moveTo( x:Number, y:Number, offset:Number=0 ):void{
			graphics.moveTo( x, y );
			//初期化
			px = x;
			py = y;
			draw_start = offset%blocksize;
			if( draw_start<=-dashsize ){
				draw_start += blocksize;
			}
		}
		
		
		/**
		* lineTo
		*/
		public function lineTo( x:Number, y:Number ):void{
			
			//ベクトル
			var v:Point = new Point( x-px, y-py );
			
			//描画長
			var length:Number = v.length;
			
			if( draw_start>=length ){
				//空線中
				draw_start -= length;
				
			}else if( draw_start<0 && (dashsize + draw_start)>length ){
				//線分中
				graphics.lineTo( x, y );
				draw_start -= length;
				
			}else{
				//正規化
				v.normalize(1.0);
				
				//破線描画単位
				var dx:Number = dashsize*v.x;
				var dy:Number = dashsize*v.y;
				
				//始点
				if( draw_start<0 ){
					//最初の線分の長さ
					var length0:Number = dashsize + draw_start;
					graphics.lineTo( px + length0*v.x, py + length0*v.y );
					draw_start += blocksize;
				}
				
				if( draw_start<length ){
					//破線
					var dx0:Number;
					var dy0:Number;
					var len:Number = draw_start;
					var draw_len:Number = length - blocksize;
					
					for( len=draw_start ; len<draw_len; len+=blocksize ){
						dx0 = px + len*v.x;
						dy0 = py + len*v.y;
						graphics.moveTo( dx0, dy0 );
						graphics.lineTo( dx0 + dx, dy0 + dy );
					}
					
					//終点
					dx0 = px + len*v.x;
					dy0 = py + len*v.y;
					var lastLen:Number = length - len;
					if( lastLen>dashsize ){
						//空線で終わる
						draw_start = blocksize - lastLen;
						lastLen = dashsize;
					}else{
						//破線途中で終わる
						draw_start = -lastLen;
					}
					graphics.moveTo( dx0, dy0 );
					graphics.lineTo( dx0 + lastLen*v.x, dy0 + lastLen*v.y );
					
				}else{
					draw_start -= length;
				}
			}
			
			px = x;
			py = y;
		}
		
		
		/**
		* curveTo
		*/
		public function curveTo( cx:Number, cy:Number, x:Number, y:Number ):void{
			
			var bezje:Bezje2D = new Bezje2D( new Point(px, py), new Point(x, y), new Point(cx, cy));
			
			//描画長
			var length:Number = bezje.length;
			
			if( draw_start>=length ){
				//空線中
				draw_start -= length;
				
			}else if( draw_start<0 && (dashsize + draw_start)>length ){
				//線分中
				graphics.curveTo( cx, cy, x, y );
				draw_start -= length;
				
			}else{
				
				//始点
				if( draw_start<0 ){
					//破線の途中
					var length0:Number = dashsize + draw_start;
					var t1:Number = bezje.length2T( length0, 0.1 );
					drawSegmentCurve( new Point(px,py), bezje.f(t1), bezje.diff(0), bezje.diff(t1) );
					draw_start += blocksize;
				}
				
				
				if( draw_start<length ){
					//終点
					var len:Number  = draw_start;
					var draw_len:Number = length - blocksize;
					
					//破線
					for( len=draw_start; len<draw_len ; len+=blocksize ){
						drawCurve( bezje, len, len+dashsize );
					}
					
					//終点
					var lastLen:Number = length - len;
					if( lastLen>dashsize ){
						//空線で終わる
						draw_start = blocksize - lastLen;
						drawCurve( bezje, len, len+dashsize );
					}else{
						//破線途中で終わる
						var t0:Number = bezje.length2T( len, 0.1 );
						var p0:Point  = bezje.f(t0);
						graphics.moveTo( p0.x, p0.y );
						drawSegmentCurve( p0, new Point(x,y), bezje.diff(t0), bezje.diff(1.0) );
						draw_start = -lastLen;
					}
					
				}else{
					draw_start -= length;
				}
			}
			
			px = x;
			py = y;
		}
		
		
		/**
		* 曲線の破線
		*/
		private function drawCurve( bezje:Bezje2D, len0:Number, len1:Number ):void{
			var t0:Number = bezje.length2T( len0, 0.1 );
			var t1:Number = bezje.length2T( len1, 0.1 );
			var p0:Point  = bezje.f(t0);
			graphics.moveTo( p0.x, p0.y );
			drawSegmentCurve( p0, bezje.f(t1), bezje.diff(t0), bezje.diff(t1) );
		}
		
		
		/**
		* ベジェ曲線の分割曲線
		*/
		private function drawSegmentCurve(p0:Point, p1:Point, pv0:Point, pv1:Point):void{
			var dx:Number = p1.x-p0.x;
			var dy:Number = p1.y-p0.y;
			var a:Number;
			if( dx != 0 ){
				a = dx/(pv1.x+pv0.x);
				graphics.curveTo( p0.x + a*pv0.x, p0.y + a*pv0.y, p1.x, p1.y );
			}else if( dy != 0 ){
				a = dy/(pv1.y+pv0.y);
				graphics.curveTo( p0.x + a*pv0.x, p0.y + a*pv0.y, p1.x, p1.y );
			}
		}
		
	}
	
}

