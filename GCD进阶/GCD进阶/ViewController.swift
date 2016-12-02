//
//  ViewController.swift
//  GCD进阶
//
//  Created by zhangyongjun on 16/5/25.
//  Copyright © 2016年 张永俊. All rights reserved.
//

/*
 相对于GCD：
 1，NSOperation拥有更多的函数可用，具体查看api。
 2，在NSOperationQueue中，可以建立各个NSOperation之间的依赖关系。
 3，有kvo，可以监测operation是否正在执行（isExecuted）、是否结束（isFinished），是否取消（isCanceld）。
 4，NSOperationQueue可以方便的管理并发、NSOperation之间的优先级。
 GCD主要与block结合使用。代码简洁高效。
 GCD也可以实现复杂的多线程应用，主要是建立个个线程时间的依赖关系这类的情况，但是需要自己实现相比NSOperation要复杂。
 */


/*
 dispatch_sync(queue, block)同步提交job
 dispatch_async (queue, block) 异步提交job
 dispatch_after(time, queue, block) 异步延迟提交job
 除了添加Block到Dispatch Queue，还有添加函数到Dispatch Queue的接口，例如dispatchasync对应的有dispatchasync_f：
 
 dispatchgetcurrent_queue()获取当前队列，一般在提交的Block中使用。在提交的Block之外调用时，如果在主线程中就返回主线程Queue；如果是在其他子线程，返回的是默认的并发队列。
 
 dispatchqueueget_label(queue)获取队列的名字，如果你自己创建的队列没有设置名字，那就是返回NULL。
 
 dispatchsettarget_queue(object, queue)设置给定对象的目标队列。这是一个非常强大的接口，目标队列负责处理这个GCD Object(参见下面的小节“管理GCD对象”)，注意这个Object还可以是另一个队列。例如我创建了了数个私有并发队列，而将它们的目标队列设置为一个串行的队列，那么我添加到这些并发队列的任务最终还是会被串行执行。
 
 dispatch_main()会阻塞主线程等待主队列Main Queue中的Block执行结束。
 
 
 dispatchgroupnotify函数可以将这个Group完成后的工作也同样添加到队列中（如果是需要更新UI，这个队列也可以是主队列），总之这样做就完全不会阻塞当前线程了。
 
 Dispatch Group还有两个接口可以显式的告知group要添加block操作：
 dispatchgroupenter(group)和dispatchgroupleave(group)，这两个接口的调用数必须平衡，否则group就无法知道是不是处理完所有的Block了。
 
 如果就是要同步的执行对数组元素的逐个操作，GCD也提供了一个简便的dispatch_apply函数：
 
 
 在使用dispatchasync异步提交时，是无法保证这些工作的执行顺序的，如果需要某些工作在某个工作完成后再执行，那么可以使用Dispatch Barrier接口来实现，barrier也有同步提交dispatchbarrierasync(queue, block)和异步提交dispatchbarrier_sync(queue, block)两种方式。例如：
 
 dispatch_async(queue, block1);
 dispatch_async(queue, block2);
 dispatch_barrier_async(queue, block3);
 dispatch_async(queue, block4);
 dispatch_async(queue, block5);
 dispatchbarrierasync是异步的，调用后立刻返回，即使block3到了队列首部，也不会立刻执行，而是等到block1和block2的并行执行完成后才会执行block3，完成后再会并行运行block4和block5。注意这里的queue应该是一个并行队列，而且必须是dispatchqueuecreate(label, attr)创建的自定义并行队列，否则dispatchbarrierasync操作就失去了意义。
 */
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        GCD_semaphore()
        
//        GCD_GroupNotify()
//        
//        GCD_GroupWait()
//
//        GCD_Apply()
//
//        GCD_Barrier()
        
//        GCD_Source()
        
//        GCD_InitiallyInactive()
        
//        GCD_After()
        
        GCD_WorkItem()
    }

    fileprivate func GCD_semaphore() {
        var mainData = 0
        //参数代表信号量，当信号量为0时，dispatch_semaphore_wait会阻塞线程，可以理解为signal会使信号量+1，wait会使信号量-1，当信号量>=0时，线程才不会被阻塞，相当于如果返回值小于0，会按照先后顺序等待其他信号量的通知
        let sem = DispatchSemaphore(value: 0)//假设初始信号量为0
        let queue = DispatchQueue(label: "StudyBlocks", attributes: [])
        
        queue.async { 
            var sum = 0
            for _ in 0..<5 {
                sum += 1
                print("sum = \(sum)")
            }
            let count = sem.signal()
            print("count = \(count)")
            //signal两次相当于信号量+2
//                    dispatch_semaphore_signal(sem);
        }
        let count2 = sem.wait(timeout: DispatchTime.distantFuture)
        print("count2 = \(count2)")
        //wait两次相当于信号量-2
//            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        for _ in 0..<5 {
            mainData += 1
            print("mainData = \(mainData)")
        }
    }

    fileprivate func GCD_GroupNotify() {
        //创建一个组
        let group = DispatchGroup()
        
//        var lock = OSSpinLock()
        
        for i in 0...10 {
            
            //加入组中，和dispatch_group_leave(group)相对，要成对出现，如果都不写，也是可以的
            group.enter()
//            OSSpinLockLock(&lock)
            
            //模仿一个异步队列
            DispatchQueue.global(qos: .default).async {
                print(i)
                //移除组
                group.leave()
                
//                OSSpinLockUnlock(&lock)
            }
        }
        
//        print("ok")
        
        //当所有都执行完后会发送通知，并且不会阻塞当前线程
        group.notify(queue: DispatchQueue.main) { 
            print("OK")
        }
        
        print("go on")
    }
    
    fileprivate func GCD_GroupWait() {
        let group = DispatchGroup()
        
        for i in 0...10 {
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(group: group, execute: { 
                print(i)
            })
        }
        //缺点是阻塞线程(在group中有任务没执行完之前，处于等待状态)
        let re = group.wait(timeout: DispatchTime.distantFuture)
        
        print("END__" + "\(re)")
    }
    
    fileprivate func GCD_Apply() {
        
        let arr = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o"];
        
        //并发操作数组中的每个元素
        DispatchQueue.concurrentPerform(iterations: arr.count) { (index) in
            print(arr[index])
        }
        
        print("OK")
    }

    fileprivate func GCD_Barrier() {
        //要使用自定义的并行队列
        let queue = DispatchQueue(label: "barrier_queue", attributes: DispatchQueue.Attributes.concurrent)
        
        //1
        queue.async { 
            print("one")
        }
        //1
        queue.async { 
            print("two")
        }
        //2   相当于添加依赖关系，当上面的执行完之后，才会执行下面的
        queue.async(flags: .barrier, execute: { 
            print("========")
        }) 
        //3
        queue.async { 
            print("three")
        }
        //3
        queue.async { 
            print("four")
        }
        
        //顺序执行
        queue.async(flags: .barrier, execute: {
            print("========")
        }) 
        queue.async(flags: .barrier, execute: {
            print("++++++++")
        }) 
        queue.sync(flags: .barrier, execute: {
            print("........")
        }) 
        queue.async(flags: .barrier, execute: {
            print("!!!!!!!!")
        }) 
        
        print("end")
    }
    
    fileprivate func GCD_Source() {
        let source = DispatchSource.makeUserDataAddSource(queue: DispatchQueue.main)
        
        source.setEventHandler { 
            print("在这里添加source的处理方法")
        }
        
        //取消source，触发下面的回调，event_handler不会再执行
//        dispatch_source_cancel(source)
        source.setCancelHandler {
            print("在这里添加source被取消后的处理")
        }
        
        //获取source需要处理的数据，和type有关
//        let data = dispatch_source_get_data(source)
        
        //dispatchsourcegethandle(source)和dispatchsourcegetmask(source)接口分布用于获取当初创建source时的两个参数handle和mask
//        let handle = dispatch_source_get_handle(source)
//        let mask = dispatch_source_get_mask(source)
        
        //dispatchsourcemergedata(source, value)接口用于将一个value值合并到souce中，这个source的类型必须是DISPATCHSOURCETYPEDATAADD或者DISPATCHSOURCETYPEDATA_OR
//        dispatch_source_merge_data(source, 1)
        
//        let data2 = dispatch_source_get_data(source)，这里data2 ＝ data ＋ 1
        
        //source创建后是suspend状态的，必须使用resume来恢复
        //dispatchsuspend(queue)可以暂停一个GCD队列的执行，当然由于是block粒度的，如果调用dispatchsuspend时正好有队列中block正在执行，那么这些运行的block结束后不会有其他的block再被执行；同理dispatchresume(queue)可以恢复一个GCD队列的运行。注意dispatchsuspend的调用数目需要和dispatchresume数目保持平衡，因为dispatchsuspend是计数的，两次调用dispatchsuspend会设置队列的暂停数为2，必须再调用两次dispatchresume才能让队列重新开始执行block。
        source.resume()
        
//        var s = self
        
//        dispatch_set_context(source as! DispatchObject, &s)
//        let ctx = dispatch_get_context(source as! DispatchObject)
//        
//        print(ctx)
    }
    
    //ios10才可用，设置attributes中包含.initiallyInactive后，队列不会立刻执行，通过activate()激活
    /*优先级
     userInteractive
     userInitiated
     default
     utility
     background
     unspecified
     */
    fileprivate func GCD_InitiallyInactive() {
        let queue = DispatchQueue(label: "com.app", qos: .utility, attributes: [.concurrent, .initiallyInactive])
        queue.async {
            for i in 0..<10 {
                print(i)
            }
        }
        queue.async {
            for i in 10..<20 {
                print(i)
            }
        }
        
        queue.activate()
    }
    
    fileprivate func GCD_After() {
        let queue = DispatchQueue(label: "com.sdj")
        //设定的等待执行时间是两秒
        let after: DispatchTimeInterval = .seconds(2)
        queue.asyncAfter(deadline: .now() + after) {
            print(2)
        }
        //直接使用一个 Double 类型的值添加到当前时间上,代表多少秒
        queue.asyncAfter(deadline: .now() + 0.5) {
            print(5 * 10e-2)
        }
        
    }
    
    fileprivate func GCD_WorkItem() {
        var value = 10
        let workItem = DispatchWorkItem { 
            value += 10
            for _ in 0...20 {
                print(456)
            }
        }
        
        //在当前线程同步执行
//        workItem.perform()

        print(123)
        
        let queue = DispatchQueue.global(qos: .utility)
        
        queue.async(execute: workItem)
        
        //异步调用的，不会阻塞线程，针对异步执行的workitem
//        workItem.notify(queue: DispatchQueue.main) {
//            print(value)
//        }
//        print(value+10)
        
        //同步执行，会阻塞线程，针对异步执行的workitem
        workItem.wait()
        print("after wait")
    }
    
}




/*
 Dispatch I/O Channel
 GCD提供的这组Dispatch I/O Channel接口用于异步处理基于文件和网络描述符的操作，可以用于文件和网络I/O操作。
 
 Dispatch IO Channel对象dispatchiot就是对一个文件或网络描述符的封装，使用dispatchiot dispatchiocreate(type, fd, queue, cleanuphander)接口生成一个dispatchiot对象。第一个参数type表示channel的类型，有DISPATCHIOSTREAM和DISPATCHIORANDOM两种，分布表示流读写和随机读写；第二个参数fd是要操作的文件描述符；第三个参数queue是cleanuphander提交需要的队列；第四个参数cleanup_hander是在系统释放该文件描述符时的回调。示例：
 
 dispatch_io_t fileChannel = dispatch_io_create(DISPATCH_IO_STREAM, STDIN_FILENO, dispatch_get_global_queue(0, 0), ^(int error) {
 if(error)
 fprintf(stderr, "error from stdin: %d (%s)\n", error, strerror(error));
 });
 dispatchioclose(channel, flag)可以将生成的channel关闭，第二个参数是关闭的选项，如果使用DISPATCHIOSTOP (0x01)就会立刻中断当前channel的读写操作，关闭channel。如果使用的是0，那么会在正常读写结束后才会关闭channel。
 
 During a read or write operation, the channel uses the high- and low-water mark values to determine how often to enqueue the associated handler block. It enqueues the block when the number of bytes read or written is between these two values.
 
 在channel的读写操作中，channel会使用lowwater和highwater值来决定读写了多大数据才会提交相应的数据处理block，可以dispatchiosetlowwater(channel, lowwater)和dispatchiosethighwater(channel, highwater)设置这两个值。
 
 Channel的异步读写操作使用接口dispatchioread(channel, offset, length, queue, iohandler)和dispatchiowrite(channel, offset, data, queue, iohandler)。dispatchioread接口参数分布表示channel，偏移量，字节大小，提交IO处理block的队列，IO处理block；dispatchiowrite接口参数分别表示channel，偏移量，数据(dispatchdatat)，提交IO处理block的队列，IO处理block。其中io_handler的定义为^(bool done, dispatch_data_t data, int error)()。
 
 举个例子，将STDIN读到的数据写到STDERR：
 
 dispatch_io_read(stdinChannel, 0, SIZE_MAX, dispatch_get_global_queue(0, 0), ^(bool done, dispatch_data_t data, int error) {
 if(data)
 {
 dispatch_io_write(stderrChannel, 0, data, dispatch_get_global_queue(0, 0), ^(bool done, dispatch_data_t data, int error) {});
 }
 });
 看起来使用上还挺麻烦的，需要创建Channel才能进行读写，因此GCD直接提供了两个方便异步读写文件描述符的接口(参数含义和channel IO的类似)：
 
 void dispatch_read(
 dispatch_fd_t fd,
 size_t length,
 dispatch_queue_t queue,
 void (^handler)(dispatch_data_t data, int error));
 
 void dispatch_write(
 dispatch_fd_t fd,
 dispatch_data_t data,
 dispatch_queue_t queue,
 void (^handler)(dispatch_data_t data, int error));
 */








